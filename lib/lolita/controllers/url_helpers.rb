module Lolita
  module Controllers
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
            if options.is_a?(Hash) !options[:use_route] && self.respond_to?(:lolita_mapping)
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
      
      def lolita_resources_path(*args)
        options=args.extract_options!
        mapping=args[0]
        send(lolita_resource_name(mapping,nil,true),options)
      end

      def lolita_resource_path(*args) # TODO test
        options=args.extract_options!
        mapping=args[0]
        send(lolita_resource_name(mapping),options)
      end

      def new_lolita_resource_path(*args)
        options=args.extract_options!
        mapping=args[0]
        send(lolita_resource_name(mapping,:new),options)
      end

      def edit_lolita_resource_path(*args)
        options=args.extract_options!
        options[:id]||=resource.id if resource
        raise "Can edit resource without id." unless options[:id]
        mapping=args[0]
        send(lolita_resource_name(mapping,:edit),options)
      end

      def lolita_resource_name(mapping=nil,action=nil,plural=nil) #TODO test if path is right
        mapping=(mapping||lolita_mapping)
        name=!plural ? mapping.name : mapping.plural
        name="#{mapping.path}_#{name}"
        :"#{action}#{action ? "_" : ""}#{name}_path"
      end
    end
  end
end
