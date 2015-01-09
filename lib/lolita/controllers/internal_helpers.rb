module Lolita
  module Controllers
    module InternalHelpers
      def include_application_assets
        result = ''
        Lolita.application.assets.each do |asset_name|
          if asset_name.match(/\.js(\.|$)/)
            result << javascript_include_tag(asset_name)
          elsif asset_name.match(/\.css(\.|$)/)
            result << stylesheet_link_tag(asset_name)
          end
        end
        raw(result)
      end

      def resource
        instance_variable_get(:"@#{resource_name}")
      end

      def resource_name
        lolita_mapping.class_name.gsub(/::/, '_').underscore.to_sym
      end

      def resource_class
        lolita_mapping.to
      end

      def lolita_mapping(new_mapping = nil)
        @lolita_mapping ||= request.env['lolita.mapping']
      end

      def current_form=(form)
        @current_form = form
      end

      def current_form(temp_form = nil)
        if block_given?
          old_form = @current_form
          @current_form = temp_form
          content = yield
          @current_form = old_form
        end
        @current_form
      end

      def use_mapping(new_mapping)
        if block_given?
          begin
            @old_mapping = lolita_mapping
            @lolita_mapping = new_mapping
            yield
          ensure
            @lolita_mapping = @old_mapping
            @old_mapping = nil
          end
        end
      end

      def is_lolita_resource?
        fail ActionController::UnknownAction unless lolita_mapping
        true
      end

      protected

      def resource=(new_resource)
        instance_variable_set(:"@#{resource_name}", new_resource)
      end
    end
  end
end
