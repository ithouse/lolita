class ErrorLog < ActiveRecord::Base
  self.abstract_class=true
  before_save :is_user_set?
  
  
  def is_user_set?
    unless self.user.to_s.size>0
      self.user="Unauthorized!"
    end
  end
end
