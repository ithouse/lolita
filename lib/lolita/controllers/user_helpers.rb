module Lolita
  module Controllers
    module UserHelpers
      extend ActiveSupport::Concern

      private
      def authenticate_lolita_user!
        true
      end

    end
  end
end
