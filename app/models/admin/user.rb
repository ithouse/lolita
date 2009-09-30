require 'digest/sha1'
class Admin::User < Cms::Base
 
  set_table_name :admin_users #Lolita.config.system(:public_user_table)
  
  attr_protected :role_ids,:crypted_password,:salt
  attr_accessor :password
  attr_accessor :old_password
  has_and_belongs_to_many :roles, :class_name=>"Admin::Role"
  
  validates_presence_of     :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_length_of       :password, :within => 4..40, :if => :password_required?

  before_save :encrypt_password

  def self.authenticate(login, password)
    login.to_s =~ /(^2\d{7}$)|(^[a-z0-9_\.\-]+)@((?:[-a-z0-9]+\.)+[a-z]{2,}$)/i
    if $&.to_s.include? "@"
      self.authenticate_by_email($&, password)
    else
      user = self.find_by_login(login) # need to get the salt
      user && user.authenticated?(password)  ? user : false
    end
  end

  def self.authenticate_by_email(email, password)
    user = self.find_by_email(email)
    user && user.authenticated?(password)  ? user : false
  end

  def validate
    allow_password_change?
  end

  def allow_password_change?
    if !(self.new_record? || Admin::User.new.has_role(Admin::Role.admin) || self.authenticated?(self.old_password))
      self.errors.add :old_password, "nepareiza vecā parole"
    end
  end

  def self.access_to_area?(ses,area=false)
    return false unless ses[:user]
    area=:public unless area
    if area==:public
      user = ses[:user][:user_class].find_by_id(ses[:user][:user_id])
      (Lolita.config.access :allow, :system_in_public && user.is_a?(Admin::SystemUser))||
        (Lolita.config.access :allow, :rewrite && user.is_a?(Admin::SystemUser)) || #ielogojoties vienā tiek otrā
      user.is_a?(Admin::PublicUser)
    elsif area==:system
    end
  end
  
  def self.authenticate_in_controller action,controller,user=nil,options={},roles=nil
    allowed=false
    action=action.to_sym
    Admin::User.current_user=nil
    Admin::User.area=nil
    if action_in?(action,options[:public])
      allowed=true
      Admin::User.area=:public
    elsif !action_in?(action,options[:all_public]) && user && user.is_a?(Admin::SystemUser) && user.is_real_user?
      Admin::User.current_user=user
      Admin::User.area=:system
      allowed=user.is_admin? || action_in?(action,options[:all]) || ((!except?(options,action)||only?(options,action)) && user.has_access?(roles,action,controller,options))
    elsif self.access_to_area?({:user => user}) && user.is_real_user?
      Admin::User.current_user=user
      allowed=action_in?(action,options[:all_public])
      Admin::User.area=:public_system
    end
    return allowed
  end

  def self.current_user=(user)
    @current_user=user
  end

  def self.current_user
    @current_user
  end

  def self.area=(area)
    @area=area
  end
  def self.area
    @area
  end

  def self.temp_password len=0
    new_pasw=""
    1.upto(len) do
      posibilities=[rand(10)+48,rand(26)+65,rand(26)+97]
      new_pasw<<posibilities[rand(3)]
    end
    new_pasw
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  def must_change_password?
    self.reset_password_expires_at
  end
  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at
  end
  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    self.remember_token_expires_at = 2.weeks.from_now.utc
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end

  #TODO vai šis nerada kādu drošības apdraudējumu
  def is_admin?
    @is_admin||=[self.has_role?(Admin::Role.admin)]
    @is_admin[0]
  end

  def has_no_role role
    if role.is_a?(Admin::Role)
      self.roles.delete(role)
    elsif role.is_a?(String) && role=Admin::Role.find_by_name(role)
      self.roles.delete(role)
    end
  end

  def has_role role
    if role.is_a?(Admin::Role)
      self.roles<<role
    elsif role.is_a?(String)
      role=Admin::Role.find_by_name(role) || Admin::Role.create!(:name=>role)
      self.roles<<role
    end
  end

  def has_role?( role_name)
    self.roles.find_by_name(role_name) ? true : false
  end

  protected

  def self.check_options? options,action
    if options
      if options.respond_to?("each")
        options.include?(action.to_sym)
      else
        (options==action)
      end
    else
      false
    end
  end

  def self.except? options,action
    check_options? options[:except],action
  end
  def self.only? options,action
    check_options? options[:only],action
  end
  def self.public? options,action
    check_options? options[:public],action
  end

  def self.action_in? action,options
    (options && options.is_a?(Hash) ? options.keys.include?(action) : (options.is_a?(Array) ? options.include?(action) : nil))
  end
  def encrypt_password
    return if password.blank?
    self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{email}--") if new_record?
    self.crypted_password = encrypt(password)
  end

  def password_required?
    crypted_password.blank? || !password.blank?
  end
end
