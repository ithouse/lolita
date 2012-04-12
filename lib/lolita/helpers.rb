module Lolita
  module Helpers

    def self.included(base)
      base.class_eval do 
        if Lolita.sinatra?
          include Lolita::Controllers::SinatraHelpers
          include Lolita::Controllers::SinatraUrlHelpers
        end
        include Lolita::Extensions
        include Lolita::Controllers::ComponentHelpers
        include Lolita::Controllers::AuthenticationHelpers
      end
    end
  end
end