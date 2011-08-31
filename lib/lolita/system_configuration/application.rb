module Lolita
  module SystemConfiguration
    class Application

      attr_writer :name

      def name
        @name || default_name
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