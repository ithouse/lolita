require 'generators/helpers/file_helper'
module Lolita
  module Generators
    class CopyAssetsGenerator < Rails::Generators::Base
      include Lolita::Generators::FileHelper
      desc "Copy all from lolita public directory to project public directory."
      def copy_all
        copy_dir("public")
      end      
    end
  end
end