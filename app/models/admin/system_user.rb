class Admin::SystemUser < Admin::User
  set_table_name :admin_users
  validates_presence_of     :login
  validates_length_of       :login,    :within => 3..40
  validates_uniqueness_of   :login, :case_sensitive => true
  validates_presence_of     :email
  validates_uniqueness_of   :email, :allow_nil => false, :scope=>:type
  validates_format_of       :email, :with=>RFC822::EmailAddress

  has_one     :photo, :as=>:pictureable, :dependent=>:destroy,:class_name=>"Media::ImageFile"

  def is_real_user?
    real_user=Admin::SystemUser.find_by_login(self.login)
    real_user==self
  end

end
