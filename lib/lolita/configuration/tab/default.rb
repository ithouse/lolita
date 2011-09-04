module Lolita
  module Configuration
    module Tab
      class Default < Lolita::Configuration::Tab::Base

        def initialize *args,&block
          super
        end

        private

        def set_default_fields
          warn("Default fields are not set for DefaultTab.")
        end

        def validate
          super
          if fields.empty?
            raise Lolita::NoFieldsGivenError, "At least one field must be specified for default tab."
          end
        end
      end
    end
  end
end