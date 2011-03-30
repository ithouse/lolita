module Lolita
  module Configuration
    class DefaultTab < Lolita::Configuration::Tab

      def initialize *args,&block
        self.type=:default
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