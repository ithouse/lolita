module Lolita
  class BaseConfiguration
  
    attr_reader :scope, :modules, :routes, :controllers
    attr_accessor :mappings,:default_module,:user_classes,:authentication

    def initialize(scope)
      @scope=scope
      @mappings={}
      @default_module=nil
      @user_classes=[]
      @modules=[]
      @routes={}
      @controllers={}
    end

    def use(module_name)

    end

    def add_mapping(resource,options={})
      mapping = Lolita::Mapping.new(resource, options)
      self.mappings[mapping.name] = mapping
      #self.default_scope ||= mapping.name
      mapping
    end

    def add_module name, options={}
      options.assert_valid_keys(:controller,:route,:model,:path)
      self.modules<<name.to_sym
      config={
        :route=>self.routes,
        :controller=>self.controllers
      }
      config.each{|key,value|
        next unless options[key]
        new_value=options[key]==true ? name : options[key]
        if value.is_a?(Hash)
          value[name]=new_value
        elsif !value.include?(new_value)
          value << new_value
        end
      }

      if options[:path]
        require File.join(options[:path],name.to_s)
      end
      #    if options[:model]
      #      model_path = (options[:model] == true ? "lolita/models/#{name}" : options[:model])
      #      Lolita::Models.send(:autoload, name.to_s.camelize.to_sym, model_path)
      #    end
    end

  end
end