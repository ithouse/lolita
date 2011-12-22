module Lolita
  module SystemConfiguration
    # This configuration is used in application lolita initializer
    # For detailed documentation see initializer.
    class Application

      attr_writer :name, :assets
      attr_accessor :per_page

      def name
        @name || default_name
      end

      def assets
         @assets ||= []
      end

      def default_name
        if defined?(Rails)
           Rails::Application.subclasses.first.to_s.split("::").first
        else
          "Lolita"
        end
      end

    end
  end
end