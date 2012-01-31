module Lolita
  module Controllers
    # Helper and controller methods that are used to authorize access to resource. Include this when auhtorization for lolita resources are needed.
    module AuthorizationHelpers

      extend ActiveSupport::Concern
      included do
        helpers = %w(current_ability can? cannot? authorize!)
       
        helper_method *helpers
      end 

      # Proxy method for current_abi, it gives control back to superclass when method is called in
      # other controller than Lolita's (it responds to #lolita_mapping) otherwise it creates or return existing ability with #lolita_current_user.
      def current_ability
        if self.respond_to?(:is_lolita_resource?) && self.is_lolita_resource? && lolita_current_user
          if defined?(::CanCan)
            @current_ability||= ::Ability.new(lolita_current_user)
          else
            super
          end
        else
          super
        end
      end

      def can? *args
        if defined?(::CanCan)
          super
        else
          true
        end
      end

      def cannot? *args
        if defined?(::CanCan)
          super
        else
          true
        end
      end

      def authorize! *args
        
        if defined?(::CanCan)
          super
        else
          true
        end
      end

    end
  end
end