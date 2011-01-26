module ActionDispatch::Routing
  
  class Mapper

    # Every module, that is used with lolita and has routes, need to have
    # <code>resource method</code>, for example, lolita_rest, that should be added
    # to ActionDispatch::Routing::Mapper class, as a *protected* method.
    # Module can automaticliy add resource route or live it to user.
    # ====Example
    #     Lolita.add_module :admins
    #     # in route.rb
    #     lolita_for :admins
    #     # if admins have route added, than new route will point to these module controller
    def lolita_for *resources
      options = resources.extract_options!

      if as = options.delete(:as)
        ActiveSupport::Deprecation.warn ":as is deprecated, please use :path instead."
        options[:path] ||= as
      end

      if scope = options.delete(:scope)
        ActiveSupport::Deprecation.warn ":scope is deprecated, please use :singular instead."
        options[:singular] ||= scope
      end

      options[:as]          ||= @scope[:as]     if @scope[:as].present?
      options[:module]      ||= @scope[:module] if @scope[:module].present?
      options[:path_prefix] ||= @scope[:path]   if @scope[:path].present?
      resources.map!(&:to_sym)
      resources.each{|resource|
        mapping=Lolita.add_mapping(resource,options)
        target_class=mapping.to
        
        lolita_scope mapping.name do
          yield if block_given?

          with_lolita_exclusive_scope mapping.fullpath,mapping.path do
            # if not defined lolita default configuration in model, than can't use :rest
            if !target_class.respond_to?(:lolita) && !Lolita::ROUTES[mapping.name]
               raise Lolita::NotFound, "Lolita not found in #{target_class}. Include Lolita::Configuration"
            elsif target_class.respond_to?(:lolita) && target_class.instance_variable_get(:@lolita).nil?
               raise Lolita::NotInitialized, "Call lolita method in #{target_class}."
            else
              route=Lolita::ROUTES[mapping.name] || Lolita::ROUTES[Lolita.default_module]
            end
            unless route
              raise Lolita::ModuleNotFound, "Module #{mapping.name.to_s.capitalize} not found! Add Lolita.use(:#{mapping.name}) to initializers/lolita.rb"
            end
            send(:"lolita_#{route}",mapping,mapping.controllers)
          end
        end
      }
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
  end
end