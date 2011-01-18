module ActionDispatch::Routing

  class RouteSet
   
  end
  
  class Mapper

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
        raise "#{mapping.to} not include Lolita::Configuration" unless mapping.to.respond_to?(:lolita)
        raise "lolita is not initialized in #{mapping.to}" if mapping.to.instance_variable_get(:@lolita).nil?
        lolita_scope mapping.name do
          yield if block_given?
          with_lolita_exclusive_scope mapping.fullpath,mapping.path do
            route=Lolita::ROUTES[mapping.name] || Lolita::ROUTES[Lolita.default_module]
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
    
    def lolita_rest mapping, controllers
      resources mapping.plural,:only=>[:index,:new,:create,:edit,:update,:destroy],
        :controller=>controllers[:rest],:module=>mapping.module
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