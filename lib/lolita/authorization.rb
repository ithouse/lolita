module Lolita
  module Authorization
    def self.included(base)
      unless base.is_a?(ActiveRecord::Base)
        base.class_eval{
          include(ControllerInstanceMethods)
        }
      end
    end

    module ControllerInstanceMethods
      def public_user?
        !current_user.is_a? Admin::SystemUser if logged_in?
      end

      def system_user?
        !public_user? if logged_in?
      end
    end
  end
end
