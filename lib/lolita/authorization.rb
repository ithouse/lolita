# To change this template, choose Tools | Templates
# and open the template in the editor.

module Lolita
  module Authorization
    def public_user?
      !current_user.is_a? Admin::SystemUser if logged_in?
    end

    def system_user?
      !public_user? if logged_in?
    end
  end
end