
module ActiveRecord
  module Generators
    class InstallGenerator < Rails::Generators::Base
      
      def generate_devise_admin
        invoke "devise", [name]
      end
    end
  end
end
