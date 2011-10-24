module Lolita
  module Controllers
    # Add method #authenticate_lolita_user!
    # that is called before each action in Lolita controllers.
    # Authentication should be defined through Lolita#setup.
    # Method call block or send given method name to current controller
    # or return True when no authentication is defined.
    # Include this if authentication is neccessary for controller.
    module UserHelpers
      extend ActiveSupport::Concern
      included do
        helpers = %w(lolita_current_user)
       
        helper_method *helpers
      end

      private

      def lolita_current_user
        @lolita_current_user ||= Lolita.user_classes.inject(nil) do |user,user_class|
          unless user
            if self.respond_to?(:"current_#{user_class.to_s.downcase}")
              self.send(:"current_#{user_class.to_s.downcase}")
            else
              false
            end
          else
            user
          end
        end
      end


      def authenticate_lolita_user!
        if auth = Lolita.authentication
          send(auth)
        else
          warn("There is no authentication. See initializers/lolita.rb")
          true
        end
      end
    end
  end
end
