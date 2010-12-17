module Lolita
  module Controllers
    module InternalHelpers
      extend ActiveSupport::Concern
      included do
        # helper LolitaHelper
        prepend_before_filter :is_lolita_resource?
      end

      def resource
        instance_variable_get(:"@#{resource_name}")
      end
      
      def resource_name
        lolita_mapping.name
      end

      def resource_class
        lolita_mapping.to
      end
      
      def lolita_mapping
        @lolita_mapping||=request.env["lolita.mapping"]
      end
      
      protected

      def is_lolita_resource?
        raise ActionController::UnknownAction unless lolita_mapping
      end

      def resource=(new_resource)
        instance_variable_set(:"@#{resource_name}",new_resource)
      end

      def build_resource(attributes={})
        attributes||=params[resource_name] || {}
        self.resource=resource_class.new(attributes)
      end

      def build_response_from(conf_part,options={})
        conf_object=resource_class.lolita.send(conf_part)
        conf_object.build(options)
      end
    end
  end
end