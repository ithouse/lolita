require 'generators/helpers/file_helper'
module Lolita
  module Generators
    class AssetsGenerator < Rails::Generators::Base
      include Lolita::Generators::FileHelper
      desc "Copy all from lolita public directory to project public directory."
      def copy_all
        copy_dir("public")
      end      

       def call_modules
        Lolita.modules.each do |module_name|
          command="#{module_name.to_s.underscore.gsub("/","_")}:assets" 
          invoke command rescue nil
        end
      end
    end
  end
end