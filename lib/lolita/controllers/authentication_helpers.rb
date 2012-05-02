module Lolita
  module Controllers
    module AuthenticationHelpers
      
      extend ActiveSupport::Concern
      included do
        if Lolita.rails?
          before_filter :authenticate_lolita_user!
        end
      end

      def authenticate_lolita_user!
        authentication_proxy.authenticate_user!
      end
    end
  end
end