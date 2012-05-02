module Lolita
  module Helpers

    def self.included(base)
      base.class_eval do 
        include Lolita::Extensions
        include Lolita::Controllers::ComponentHelpers
        include Lolita::Controllers::AuthenticationHelpers
      end
    end
  end
end