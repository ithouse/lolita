require 'generators/helpers/file_helper'

module Lolita
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Lolita::Generators::FileHelper
      source_root File.expand_path("../../templates", __FILE__)
      desc "Create lolita initializer. Copy assets and create migrations. Load seed data."

      
      def copy_initializer
        template "lolita.rb", "config/initializers/lolita.rb" unless file_exists?("config/initializers/lolita.rb")
      end

      def copy_assets
        generate("lolita:copy_assets")
      end

      def load_seed
        eval(File.new(File.join(LOLITA_ROOT,"db","seed.rb")).read)
      end
     
    end
  end
end
