module ActionDispatch::Routing
  
  class RouteSet

    def draw_with_lolita  *args,&block
      unless Lolita::Navigation::Tree[:"left_side_navigation"]
        tree=Lolita::Navigation::Tree.new(:"left_side_navigation")
        Lolita::Navigation::Tree.remember(tree)
      end
      draw_without_lolita *args,&block
    end

    alias_method_chain :draw, :lolita
  end

  class Mapper

    # Every module, that is used with lolita and has routes, need to have
    # <code>resource method</code>, for example, lolita_rest, that should be added
    # to ActionDispatch::Routing::Mapper class, as a *protected* method.
    # Module can automaticliy add resource route or allow user to do it.
    # It accepts some useful options
    # * <tt>:module</tt>
    # * <tt>:path</tt>
    # * <tt>:as</tt>
    # * <tt>:path_prefix</tt>
    # * <tt>:controller</tt>
    # * <tt>:class_name</tt>
    # * <tt>:singular</tt>
    # ====Example
    #     Lolita.add_module Lolita::Gallery,:route=>:gallery
    #     # in route.rb
    #     lolita_for :galleries
    #     # lolita_for try to call :lolita_gallery in Mapper class
    def lolita_for *resources
      #TODO refactor
      return if migrating?
      options = resources.extract_options!

      # if as = options.delete(:as)
      #   ActiveSupport::Deprecation.warn ":as is deprecated, please use :path instead."
      #   options[:path] ||= as
      # end

      # if scope = options.delete(:scope)
      #   ActiveSupport::Deprecation.warn ":scope is deprecated, please use :singular instead."
      #   options[:singular] ||= scope
      # end

      options[:as]          ||= @scope[:as]     if @scope[:as].present?
      options[:module]      ||= @scope[:module] if @scope[:module].present?
      options[:path_prefix] ||= @scope[:path]   if @scope[:path].present?
      resources.map!(&:to_sym)
      all_resource_classes=[]
      resources.each{|resource|
        mapping=Lolita.add_mapping(resource,options)
        Lolita.resources[mapping.name]=mapping
        target_class=mapping.to
        Lolita::Navigation::Tree[:"left_side_navigation"].append(mapping,:title=>mapping.name.to_s.humanize)
        all_resource_classes<<target_class

        lolita_scope mapping.name do
          yield if block_given?

          with_lolita_exclusive_scope mapping.fullpath,mapping.path do
            # if not defined lolita default configuration in model, than can't use :rest
            if !target_class.respond_to?(:lolita) && !Lolita::routes[mapping.name]
               warn("Lolita not found in #{target_class}. Including Lolita::Configuration")
               target_class.send(:include, Lolita::Configuration)
               #raise Lolita::NotFound, "Lolita not found in #{target_class}. Include Lolita::Configuration"
            elsif target_class.respond_to?(:lolita) && target_class.instance_variable_get(:@lolita).nil?
               warn "Calling #lolita on #{target_class}, because lolita not initialized yet."
               target_class.lolita
               #raise Lolita::NotInitialized, "Call lolita method in #{target_class}."
            else
              route=Lolita.routes[mapping.name] || Lolita.default_route
            end
            unless route
              raise Lolita::ModuleNotFound, "Module #{mapping.name.to_s.capitalize} not found!"
            end
            send(:"lolita_#{route}_route",mapping,mapping.controllers)
            
            Lolita.conditional_routes(target_class).each do |route_name|
              send(:"lolita_#{route_name}_route",mapping,mapping.controllers)
            end
          end

        end
      }
      Lolita.common_routes(all_resource_classes).each do |route_name|
        send(:"lolita_#{route_name}_route")
      end
    end

    protected
    
    def lolita_scope scope
      constraint = lambda do |request|
        request.env["lolita.mapping"] = Lolita.mappings[scope]
        true
      end

      constraints(constraint) do
        yield
      end
    end
    
    def with_lolita_exclusive_scope new_path,new_as
      old_as, old_path, old_module = @scope[:as], @scope[:path], @scope[:module]
      @scope[:as], @scope[:path], @scope[:module] = new_as, new_path, nil
      yield
    ensure
      @scope[:as], @scope[:path], @scope[:module] = old_as, old_path, old_module
    end

    private

    def migrating?
      File.basename($0)=="rake" && (ARGV.include?("db:migrate"))
    end
  end
end