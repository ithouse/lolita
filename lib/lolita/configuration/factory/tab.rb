module Lolita
  module Configuration
    module Factory
      class Tab

        def self.add(dbi,*args, &block)
          type = args && args[0].is_a?(Symbol) ? args[0] : :default
          field_class(type).new(dbi,*args,&block)
        end

        def self.field_class(name)
          ("Lolita::Configuration::Tab::"+name.to_s.camelize).constantize
        end

      end
    end
  end
end