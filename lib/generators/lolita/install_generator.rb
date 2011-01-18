
module Lolita
  module Generators
    class InstallGenerator < Rails::Generators::Base
      
      source_root File.expand_path("../../templates", __FILE__)
      desc "Create lolita initializer. Copy assets and create migrations. Load seed data."
      hook_for :orm
      
      def copy_initializer
        template "lolita.rb", "config/initializers/lolita.rb" unless file_exists?("config/initializers/lolita.rb")
      end

      def copy_assets
        copy_dir("public")
        #rake("lolita:install:assets")
      end

      def copy_migrations
        copy_dir(File.join("db","migrate"))
        #rake("lolita:install:migrations")
      end

      def load_seed
        eval(File.new(File.join(LOLITA_ROOT,"db","seed.rb")).read)
      end

      private

      def copy_dir(source)
        root_dir=File.join(LOLITA_ROOT,source)
        Dir[File.join(root_dir, "**/*")].each do |file|
          relative = file.gsub(/^#{root_dir}\//, '')
          if File.file?(file)
            copy_file file, File.join(Rails.root, source, relative)
          end
        end
      end
      
      def file_exists? path
        File.exists?(File.join(destination_root, path))
      end
    end
  end
end
