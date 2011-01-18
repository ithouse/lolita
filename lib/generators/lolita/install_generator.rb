
module Lolita
  module Generators
    class InstallGenerator < Rails::Generators::Base
      
      source_root File.expand_path("../../templates", __FILE__)
      desc "Create lolita initializer. Copy assets and create migrations. Load seed data."
      
      def copy_initializer
        template "lolita.rb", "config/initializers/lolita.rb" unless file_exists?("config/initializers/lolita.rb")
      end

      def copy_assets
        rake("lolita:install:assets")
      end

      def copy_migrations
        rake("lolita:install:migrations")
      end

      def load_seed
        Lolita::Engine.load_seed
      end

      private
      
      def file_exists? path
        File.exists?(File.join(destination_root, path))
      end
    end
  end
end
