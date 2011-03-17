module Lolita
  module Controllers
    module ViewUserHelpers
    	 def lolita_current_user
	        if self.respond_to?(:"current_#{Lolita.user_classes.first.to_s.downcase}")
	          send(:"current_#{Lolita.user_classes.first.to_s.downcase}")
	        else
	          false
	        end
         end
    end
  end
end