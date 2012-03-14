module Lolita
  module SystemConfiguration
    class Base
      attr_reader :scope, :modules, :routes, :controllers,:resources
      attr_accessor :mappings,:default_route,:user_classes,:authentication,:authorization
      attr_writer :default_locale, :ability_class

      def initialize(scope)
        @scope=scope
        @mappings={}
        @resources={}
        @default_module=nil
        @user_classes=[]
        @modules=[]
        @routes={}
        @controllers={}
      end

      def application &block
        @application ||= Lolita::SystemConfiguration::Application.new
        if block_given?
          yield @application
        end
        @application
      end

      def navigation
        unless Lolita::Navigation::Tree[:"left_side_navigation"]
          tree = Lolita::Navigation::Tree.new(:"left_side_navigation")
          Lolita::Navigation::Tree.remember(tree)
        end
        Lolita::Navigation::Tree[:"left_side_navigation"]
      end
      
      def ability_class
        @ability_class || Ability
      end

      def locales=(value)
        unless value.is_a?(Array)
          @locales=[value]
        else
          @locales=value
        end
      end

      def locales
        @locales || []
      end

      def locale()
        @locale || default_locale
      end

      def locale=given_locale
        @locale=if locales.include?(given_locale.to_s.to_sym)
          given_locale.to_s.to_sym
        else
          Lolita.default_locale
        end
      end
      # Return default locale. First looks for defined default locale for Lolita, when not found than
      # take first of defined #locales for Lolita, if there no defined locales for Lolita, than
      # look for I18n and take default locale from there or if there is no I18n than take :en
      def default_locale
        @default_locale || self.locales.first || (defined?(::I18n) ? ::I18n.default_locale : :en)
      end
      # Call (with #call) to route klass
      # And return all names of routes that are needed for resource.
      # When with #add_module routes are defined like 
      #     Lolita.add_module MyModule, :route=>:my_module
      # then this will be passed to the method that creates routes, but 
      # when Proc is passed to <i>:route</i> then this Proc should return
      # name of route or nil.
      # These names then are used for methods like <em>lolita_[route_name]_route</em>
      # that should be required somewhere in you module.
      def conditional_routes(klass=nil)
        @routes.map{|name,route|
          if route.first
            if route.last.respond_to?(:call)
              route.last.call(klass)
            else
              route.last
            end
          end
        }.compact
      end

      # Find all routes that is needed for defined classes
      # And return only one for each different route.
      def common_routes(klasses)
        @routes.map{|name,route|
          unless route.first
            klasses.map{|klass| route.last.respond_to?(:call) ? route.last.call(klass) : route.last}
          end
        }.flatten.compact.uniq
      end
        
      # Include module in Lolita, don't know why i need this
      def use(module_name)
        Lolita.send(:include,module_name)
      end

      def add_mapping(resource,options={})
        mapping = Lolita::Mapping.new(resource, options)
        self.mappings[mapping.name] = mapping
        mapping
      end

      # Add new module to Lolita
      # Accpted options
      # * <tt>controller</tt> - not in use
      # * <tt>nested</tt> - is route stands itsefl or is used in combination with resource
      # * <tt>route</tt> - Symbol of route name or lambad, that return route name based on resource.
      # Route name is used to call method lolita_[route_name] in Mapper class, and that should draw route.
      # * <tt>:name</tt> - name of module, underscored symbol. Used to draw default route, by default always
      # lolita_rest is called, but if route with resource name is found, than by default this route will be drawn.
      # Like lolita_for :posts, can go to different controller than rest and do other things.
      # * <tt>:path</tt> - some file that will be included. Deprecated will be removed
      # ====Example
      #     Lolita.add_module Lolita::Posts, :route=>:post, :name=>:post
      #     lolita_for :posts #=> create url whatever is defined in lolita_post method, and goes to :controller=>"lolita/posts"
      #     Lolita.add_module Lolita::FileUpload, :route=>lambda{|resource| resource.lolita.tabs.by_type(:file) ? :file_upload : nil}
      #     lolita_for :users #=> creat default rest urls and also call method lolita_file_upload if user lolita define :file tab.
      # To add route for public interface that goes to added module, than use 
      #    Lolita.add_module Post, :name=>:posts
      # And then when in routes.rb will be defined lolita_for(:posts) it will call method <i>lolita_posts_route</i>
      # and that method should define resource. 
      # ====Example
      #     # require this in your gem or lib
      #     module ActionDispatch::Routing
      #        class Mapper
      #          protected
      #          def lolita_posts_route mapping, controllers
      #            resources mapping.plural,:only=>[:index,:new,:create],
      #              :controller=>controllers[:posts],:module=>mapping.module
      #          end
      #        end
      #      end
      # You open Mapper class and add your method that call #resources or #match or other method that define route
      # For common route for all lolita resources your method should look like this
      # ====Example
      #     def lolita_files_route 
      #        mapping=Lolita.add_mapping(:files,:class_name=>"Lolita::Multimedia::File",:module=>"file_upload")
      #        scope :module=>mapping.module do
      #            resources mapping.name
      #        end
      #     end
      def add_module module_container, options={}
        raise ArgumentError, "Can't add module without module container!" unless module_container
        options.assert_valid_keys(:controller,:route,:model,:path,:name,:nested)
        name=options[:name]||module_container.to_s.to_sym
        self.modules<<module_container

        if options.has_key?(:route)
          self.routes[name]=[options.has_key?(:nested) ? options[:nested] : true,options[:route]]
        end
        self.controllers[name]=options[:controller] if options.has_key?(:controller)

        if options[:path]
          require File.join(options[:path],name.to_s)
        end
    
      end
      
    end
  end
end