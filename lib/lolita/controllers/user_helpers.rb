module Lolita
  module Controllers
    # Add method #authenticate_lolita_user!
    # that is called before each action in Lolita controllers.
    # Authentication should be defined through Lolita#setup.
    # Method call block or send given method name to current controller
    # or return True when no authentication is defined.
    module UserHelpers
      extend ActiveSupport::Concern
      included do
        helper LolitaHelper
      end
      
      private
    # FIXME what to do when block or method return false, and do not redirect
    # need some redirect, but how to detect it?
      def authenticate_lolita_user!
        if auth=Lolita.authentication
          if auth.is_a?(Proc)
            self.instance_eval(&auth)
          else
            send(auth)
          end
        else
          #TODO warning
          true
        end
      end

    end
  end
end
