module Lolita
  module Controllers
    module InternalHelpers
      include Lolita::Controllers::UrlHelpers
      include Lolita::Controllers::FieldHelpers
      
      extend ActiveSupport::Concern
      included do
        if self.is_a?(ActionController::Base)
          helper LolitaHelper
           
          helpers = %w(resource resource_name
                     resource_class lolita_mapping)
          hide_action *helpers
          helper_method *helpers
          prepend_before_filter :is_lolita_resource?
        end
      end

      # Return instance variable named as resource
      # For 'posts' instance variable will be @posts
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

      def resource_attributes
        params[resource_name] || {}
      end

      def resource_with_attributes(current_resource,attributes={})
        attributes||=resource_attributes
        attributes.each{|key,value|
          current_resource.send(:"#{key}=",value)
        }
        current_resource
      end

      def get_resource(id=nil)
        self.resource=resource_class.find_by_id(id || params[:id])
      end

      def build_resource(attributes={})
        attributes||=resource_attributes
        self.resource=resource_with_attributes(resource_class.new,attributes)
      end

      def build_response_for(conf_part,options={})
        conf_object=resource_class.lolita.send(conf_part.to_sym)
        render_cell *conf_object.build(options)
      end
      
    end
  end
end