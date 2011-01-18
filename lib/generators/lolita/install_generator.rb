
module Lolita
  module Generators
    class InstallGenerator < Rails::Generators::Base
      
      source_root File.expand_path("../../templates", __FILE__)
      desc "Create lolita initializer."
      
      def copy_initializer
        template "lolita.rb", "config/initializers/lolita.rb" unless file_exists?("config/initializers/lolita.rb")
      end
  
      def copy_devise_migration
        if defined?(ActiveRecord) && defined?(ActiveRecord::Base)
          template "migrations/devise_lolita_admin.rb", "db/migrate/#{next_migration_nr}_devise_create_lolita_admins.rb"
        end
      end

      private

      def next_migration_nr
        Time.now.utc.strftime("%Y%m%d%H%M%S")
      end
      
      def file_exists? path
        File.exists?(File.join(destination_root, path))
      end
    end
  end
end
