require 'generators/lolita/file_helper'

module Lolita
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Lolita::Generators::FileHelper
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
        copy_dir(File.join("db","migrate")) if orm==:active_record
        #rake("lolita:install:migrations")
      end

      def load_seed
        eval(File.new(File.join(LOLITA_ROOT,"db","seed.rb")).read)
      end
     
    end
  end
end
