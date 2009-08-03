require 'digest/sha1'
class Admin::User < Cms::Base
  @current_user=nil
  @area=nil
  acts_as_authorized_user
  attr_protected :type
  
  set_table_name :admin_users
  attr_accessor :password
  attr_accessor :old_password
  validates_presence_of     :login, :email
  validates_presence_of     :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_length_of       :login,    :within => 3..40
  validates_length_of       :email,    :within => 3..100
  validates_uniqueness_of   :login, :email, :case_sensitive => true
  before_save :encrypt_password
  after_update :sync_email_address

  has_one     :photo, :as=>:pictureable, :dependent=>:destroy,:class_name=>"Picture"
  has_one     :email_address,   :class_name=>"Admin::Email", :dependent=>:delete
  
  has_many    :tokens, :class_name=>"Admin::Token", :dependent=>:destroy


  def self.user_activities
    lines=[]
    file_name=RAILS_ROOT+"/log/user_activities.log"
    if File.exist?(file_name)
      file=File.open(file_name,"r")
      file.each_line do |line|
        lines<<line
      end
      file.close
    end
    start=lines.size<1000 ? 0 : lines.size-1000
    lines.slice(start,1000).reverse.join("")
  end

  def self.clear_user_activities
    file_name=RAILS_ROOT+"/log/user_activities.log"
    if File.exist?(file_name)
      file=File.open(file_name,"w")
      file.close
    end
  end

  def self.get_blogger_by_url(blogger)
    if (blogger.to_i>0 && blogger.to_i.to_s.size==blogger.to_s.size)
      self.find_by_id(blogger)
    else
      profile=Cms::Profile.find_by_url(blogger)
      profile.user if profile
    end
  end
  
  def self.access_to_area?(ses,area=false)
    area=:public unless area
    if area==:public
      (LOLITA_ALLOW[:system_in_public] && ses[:p_user].is_a?(Admin::SystemUser)) ||
        (LOLITA_ALLOW[:rewrite] && ses[:user].is_a?(Admin::SystemUser)) || #ielogojoties vienā tiek otrā
      ses[:p_user].is_a?(Admin::PublicUser)
    elsif area==:system
    end
  end

  def validate
    allow_password_change?
  end

  def login_name
    self.profile && self.profile.name(true).to_s.size>0 ? "#{self.login} (#{self.profile.name})" : self.login
  end
  
  def name
    self.profile && self.profile.name.to_s.size>0 ? self.profile.name : self.login
  end

  def name_or_id
    self.profile && self.profile.name(true).to_s.size>0 ? self.profile.name : self.id
  end
  
  def ocupation
    self.profile ? self.profile.ocupation : ""
  end
  def allow_password_change?
    if !(self.new_record? || Admin::User.new.has_role(Admin::Role.admin) || self.authenticated?(self.old_password))
      self.errors.add :old_password, "nepareiza vecā parole"
    end
  end

  def self.authenticate_in_controller action,controller,users={},options={},roles=nil
    allowed=false
    action=action.to_sym
    Admin::User.current_user=nil
    if action_in?(action,options[:public])
      allowed=true
      Admin::User.area=:public
    elsif !action_in?(action,options[:all_public]) && users[:system] && users[:system].is_a?(Admin::SystemUser) && users[:system].is_real_user?
      Admin::User.current_user=users[:system]
      Admin::User.area=:system
      allowed=users[:system].is_admin? || action_in?(action,options[:all]) || ((!except?(options,action)||only?(options,action)) && users[:system].has_access?(roles,action,controller,options))
    elsif self.access_to_area?({:p_user=>users[:public],:user=>users[:system]}) && users[:public].is_real_user?
      Admin::User.current_user=users[:public]
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
  protected

  def sync_email_address
    if @changed_attributes && @changed_attributes.has_key?("email")
      if self.email_address
        self.email_address.address=self.email
        self.email_address.save!
      end
    end
  end
  
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
    self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
    self.crypted_password = encrypt(password)
  end

  def password_required?
    crypted_password.blank? || !password.blank?
  end
end