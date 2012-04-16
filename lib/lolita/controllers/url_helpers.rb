module Lolita
  module Controllers
    # This module is included in all controllers and views. UrlHelper provide methods to generate lolita
    # resource paths. As all resources goes to one controller (by default), than it is very difficult to
    # generate url with <em>:controller</em> and <em>:action</em>. 
    # There are four methods for path:
    # * lolita_resources_path - goes to index action
    # * lolita_resource_path - goes to create, destroy or show, it depends what kind of method is used
    # * new_lolita_resource_path - goes to new action
    # * edit_lolita_resource_path - goes to edit action
    # All of those methods accept <em>mapping</em> as a first argument and optional <em>options</em> that
    # will be passed to path gererator. It is possible to pass only options, than current mapping will be used.
    # ====Example
    #     # lets say, that current mapping is for posts
    #     edit_lolita_resource_path(:id=>4) #=> /lolita/posts/4/edit
    #     edit_lolita_resource_path(comment_mapping,:id=>1,:parent_id=>2) #=> /lolita/comments/1/edit?parent_id=2
    # For custom actions there are method #lolita_resource_name that make it easier to generate custom method.
    # All other methods use that for real resource path method generation.
    module UrlHelpers

      def self.included(model_klass)
        model_klass.class_eval do

          # Overrides url_for when controller or view uses this helper.
          # It catches hash options and replaces with lolita named route
          # Without this method routes always looks like /lolita/rest/[method]
          # ====Example
          #     # in routes.rb
          #     lolita_for :posts
          #     # GET /lolita/posts
          #     # in view
          #     url_for #=> /lolita/posts
          #     url_for(:controller=>"/posts",:action=>:index) #=> /posts
          #     # GET /posts
          #     url_for #=> /posts
          def url_for_with_lolita options = {}
            if options.is_a?(Hash) && !options[:use_route] && self.respond_to?(:lolita_mapping) && self.lolita_mapping
              controller = options[:controller].to_s
              if Lolita.mappings[lolita_mapping.name].controllers.values.include?(controller)
                resource_type = {
                  :index => :lolita_resources_path,
                  :new => :new_lolita_resource_path,
                  :edit => :edit_lolita_resource_path,
                  :create => :lolita_resources_path
                }
                action = (options[:action] || params[:action]).to_sym
                options = self.send(resource_type[action] || :lolita_resource_path,options)
              end
            end
            
            url_for_without_lolita(options)
          end
          alias_method_chain :url_for, :lolita

        end
      end

      protected
      
      # Path for index.
      def lolita_resources_path(*args)
        options=args.extract_options!
        mapping=args[0]
        send(lolita_resource_name(:mapping=>mapping,:plural=>true),options)
      end

      # Path for show, create and destroy
      def lolita_resource_path(*args) 
        options=args.extract_options!
        mapping=args[0]
        send(lolita_resource_name(:mapping=>mapping),options)
      end

      # Path for new.
      def new_lolita_resource_path(*args)
        options=args.extract_options!
        mapping=args[0]
        send(lolita_resource_name(:mapping=>mapping,:action=>:new),options)
      end

      # Path for edit.
      def edit_lolita_resource_path(*args)
        options=args.extract_options!
        options[:id]||=resource.id if resource
        #raise "Can edit resource without id." unless options[:id]
        mapping=args[0]
        send(lolita_resource_name(:mapping=>mapping,:action=>:edit),options)
      end

      # It return symbol, that represents named route method for path, like <i>lolita_posts_path</i> and so on.
      # It accepts those options: 
      # * <tt>:mapping</tt> - Lolita::Mapping object, that is used to detect name of named route.
      # by default it uses Lolita::InternalHelpers#lolita_mapping.
      # * <tt>:plural</tt> - What kind of named route should use, plural or singular.
      # * <tt>:action</tt> - Action is used to put before named route like <i>:edit</i>.
      # ====Example
      #     # current mapping is for posts
      #     lolita_resource_name(:action=>:edit) #=> :edit_lolita_post_path
      #     lolita_resource_name(:plural=>true,:action=>:list) #=> :list_lolita_posts_path
      #     # for different mapping 
      #     lolita_resource_name(:mapping=>comments_mapping) #=> :lolita_comment_path
      # This methods is very useful to create your own paths in views.
      def lolita_resource_name(options={}) #TODO test if path is right
        options.assert_valid_keys(:mapping,:plural,:action)
        mapping=(options[:mapping]||lolita_mapping)
        name=!options[:plural] ? mapping.name : mapping.plural
        name="#{mapping.path}_#{name}"
        addon = if mapping.plural == mapping.singular && options[:plural]
          "_index"
        end
        :"#{options[:action]}#{options[:action] ? "_" : ""}#{name}#{addon}_path"
      end
    end
  end
end
