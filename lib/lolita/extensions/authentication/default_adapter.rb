module Lolita
  module Extensions
    module Authentication

      class DefaultAdapter
        def initialize context, options={}
        end

        def current_user
          nil
        end

        def user_signed_in?
          false
        end

        def authenticate_user!
          true
        end
      end

    end
  end
end
