class Admin::SystemUser < Admin::User
  set_table_name :admin_users
  attr_protected :type
  validates_presence_of     :login, :email
  validates_length_of       :login,    :within => 3..40
  validates_length_of       :email,    :within => 3..100
  validates_uniqueness_of   :login, :email, :case_sensitive => true
  has_one     :photo, :as=>:pictureable, :dependent=>:destroy,:class_name=>"Media::ImageFile"

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    user = self.find_by_login(login) # need to get the salt
    user && user.authenticated?(password)  ? user : false
  end

  def self.authenticate_by_any(login, password)
    login.to_s =~ /(^2\d{7}$)|(^[a-z0-9_\.\-]+)@((?:[-a-z0-9]+\.)+[a-z]{2,}$)/i
    if $&.to_s.include? "@"
      self.authenticate_by_email($&, password)
    else
      self.authenticate(login.to_s, password)
    end
  end

#  def has_access? controller_name
#    return !all_accesses(controller_name).empty?
#  end

  # Nosaka vai ir pieeja
  # 1. gadījumā, ja ir pieeja lomai vai lomām, tad atļauj ja lietotājam ir šī loma
  # 2. gadījums, ja ir kāda loma, kam ir pieeja dotajam modulim ar doto notikumu, dotajam pieejas līmenim
  # allow "editor"
  #   /cms/news/list = > atļauj, ja lietotājam ir loma "editor"
  # allow
  #   /cms/news/list = > atļauj, ja lietotājam ir kāda loma ar :read tiesībām Cms::News modulim
  def has_access? roles,action=nil,controller=nil,options={}
    roles=[roles] if roles.is_a?(String)
    if roles && !roles.empty?
      Admin::SystemUser.find_by_sql(["
        SELECT admin_users.id FROM admin_users
        INNER JOIN roles_users ON roles_users.user_id=admin_users.id
        WHERE roles_users.role_id IN
          (SELECT id FROM admin_roles WHERE name IN (?)) AND roles_users.user_id=?
        LIMIT 1",roles,self.id]).empty? ? false : true
    else
      return self.can_access_action?(action,controller,options)
    end
  end

  def is_real_user?
    real_user=Admin::SystemUser.find_by_login(self.login)
    real_user==self
  end

end
