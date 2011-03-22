module Lolita
  # Base::Configuration methods are accessable through Lolita module.
  # Like Lolita.modules and Lolita.routes and so on.
  class BaseConfiguration
  
    attr_reader :scope, :modules, :routes, :controllers
    attr_accessor :mappings,:default_route,:user_classes,:authentication

    def initialize(scope)
      @scope=scope
      @mappings={}
      @default_module=nil
      @user_classes=[]
      @modules=[]
      @routes={}
      @controllers={}
    end

    def conditional_routes(klass=nil)
      @routes.map{|name,route|
        if route.is_a?(Proc)
          route.call(klass)
        else
          nil
        end
      }.compact
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
    def add_module module_container, options={}
      options.assert_valid_keys(:controller,:route,:model,:path,:name)
      name=options[:name]||module_container.to_s.to_sym
      self.modules<<module_container
      config={
        :route=>self.routes,
        :controller=>self.controllers
      }
      config.each{|key,value|
        next unless options[key]
        new_value=options[key]
        if value.is_a?(Hash)
          value[name]=new_value
        elsif value.is_a?(Proc)
          value[name]=new_value
        elsif value.respond_to?(:include?) && !value.include?(new_value)
          value << new_value
        end
      }

      if options[:path]
        require File.join(options[:path],name.to_s)
      end
  
    end

    # Lolita.extend_route_for(:any,:posts,:file_upload) do |resource|
    #   if resource.tabs.by_type(:metadata)
    #     with do
    #       resources :metadata
    #     end 
    #   end
    #end
    # :any for any
    # lolita/posts/metadata
    # lolita/posts/files/metadata
    def lolita_extend_route_for()
    end
  end
end