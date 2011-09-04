require 'generators/helpers/file_helper'

module Lolita
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Lolita::Generators::FileHelper
      source_root File.expand_path("../../templates", __FILE__)
      desc "Create lolita initializer."

      
      def copy_initializer
        template "lolita.rb", "config/initializers/lolita.rb" unless file_exists?("config/initializers/lolita.rb")
      end

      def install_modules
        Lolita.modules.each do |module_name|
          
          invoke "#{module_name.to_s.underscore.gsub("/","_")}:install"  rescue nil
        end
      end
     
    end
  end
end
