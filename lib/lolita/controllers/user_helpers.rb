module Lolita
  module Controllers
    module UserHelpers
      extend ActiveSupport::Concern

      private
      def authenticate_lolita_user!
        Lolita.user_classes.each{|class_name|
          if self.send(:"current_#{class_name}")
            self.send(:"authenticate_#{class_name}!")
            return true
          end
        }
        authenticate_admin!
      end

    end
  end
end
