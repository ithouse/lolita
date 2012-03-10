module Lolita
  module Controllers
    module AuthenticationHelpers
      
      extend ActiveSupport::Concern
      included do
        before_filter :authenticate_lolita_user!
      end

      def authenticate_lolita_user!
        authentication_proxy.authenticate_user!
      end
    end
  end
end