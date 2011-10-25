module Lolita
  # Basic module for custom Lolita controllers. Is used in Lolita::RestController.
  module ControllerAdditions
    
    def self.included(base_class)
      base_class.class_eval do 
        include Lolita::Controllers::UserHelpers
        include Lolita::Controllers::InternalHelpers
        include Lolita::Controllers::AuthorizationHelpers
        include LolitaHelper
      end
    end

  end
end