# coding:utf-8
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
  validates_uniqueness_of   :email, :allow_nil => true, :scope=>:type
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

  def self.access_to_area?(user,area=false)
    true #FIXME
#    return false unless ses[:user]
#    area=:public unless area
#    if area==:public_system
#      (Lolita.config.access :allow, :system_in_public && user.is_a?(Admin::SystemUser))||
#        (Lolita.config.access :allow, :rewrite && user.is_a?(Admin::SystemUser)) || #ielogojoties vienā tiek otrā
#      user.is_a?(ses[:user][:user_class])
#    elsif area==:system
#    end
  end
  
  def self.authenticate_in_controller options={}
    options[:permissions]||={}
    set_area_and_user()
    allowed=if action_in?(options,:public)
      set_area_and_user(:public)
      true
    elsif !action_in?(options,:all_public) && options[:user] && options[:user].is_a?(Admin::SystemUser)
      set_area_and_user(:system,options[:user])
      options[:user].is_admin? || action_in?(options,:all) || ((!except?(options)||only?(options)) && (options[:user] && options[:user].has_access?(options)))
    elsif self.access_to_area?(options[:user])
      set_area_and_user(:public_system,options[:user])
      action_in?(options,:all_public) || (options[:user] && options[:user].has_access?(options))
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

  #can be used in forms as a checkbox field
  def remember_user
    remember_token?
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
    elsif role.is_a?(String) || role.is_a?(Symbol)
      role=Admin::Role.find_by_name(role.to_s) || Admin::Role.create!(:name=>role.to_s)
      self.roles<<role
    end
  end

  def has_role?(role)
    self.roles.find_by_name(role.is_a?(Admin::Role) ? role.name : role.to_s) ? true : false
  end

  # Nosaka vai ir pieeja
  # 1. gadījumā, ja ir pieeja lomai vai lomām, tad atļauj ja lietotājam ir šī loma
  # 2. gadījums, ja ir kāda loma, kam ir pieeja dotajam modulim ar doto notikumu, dotajam pieejas līmenim
  # allow "editor"
  #   /cms/news/list = > atļauj, ja lietotājam ir loma "editor"
  # allow
  #   /cms/news/list = > atļauj, ja lietotājam ir kāda loma ar :read tiesībām Cms::News modulim
  def has_access? options={}
    #roles,action=nil,controller=nil,options={}
    roles=[options[:roles]] if options[:roles].is_a?(String)
    if roles && !roles.empty?
      Admin::User.find_by_sql(["
        SELECT admin_users.id FROM admin_users
        INNER JOIN roles_users ON roles_users.user_id=admin_users.id
        WHERE roles_users.role_id IN
          (SELECT id FROM admin_roles WHERE name IN (?)) AND roles_users.user_id=?
        LIMIT 1",roles,self.id]).empty? ? false : true
    else
      return self.can_access_action?(options[:action],options[:controller],options[:permissions])
    end
  end

  def can_all? controller_name
    actions=can_what? controller_name
    actions[:read] && actions[:write] && actions[:update] && actions[:delete]
  end
  def can_anything? controller_name
    actions=can_what? controller_name
    actions[:read] || actions[:write] || actions[:update] || actions[:delete]
  end

  def can? controller_name,permission
    all_accesses(controller_name,{:permission=>permission}).empty? ? false : true
  end

  def can_delete? controller_name
    can? controller_name, :delete
  end

  def can_read? controller_name
    can? controller_name, :read
  end

  def can_what? controller_name
    permissions={:read=>false,:write=>false,:update=>false,:delete=>false}
    access=all_accesses(controller_name,:select=>"MAX(allow_read) as allow_read,MAX(allow_write) as allow_write,
        MAX(allow_update) as allow_update,MAX(allow_delete) as allow_delete"
    ).first
    if access
      permissions[:read]=access['allow_read'].to_i>0
      permissions[:write]=access['allow_write'].to_i>0
      permissions[:update]=access['allow_update'].to_i>0
      permissions[:delete]=access['allow_delete'].to_i>0
    end
    permissions
  end

  def can_write? controller_name
    can? controller_name, :write
  end

  def can_update? controller_name
    can? controller_name, :update
  end

  def can_access_action?(action,controller,options={})
    can_access,found=self.can_access_special_action?(action,controller,options)
    unless !action || found #lai iekļautu iespēju pārrakstīt pieeju noklusētajām metodēm
      case action.to_sym
      when :list,:read,:open,:index
        self.can_read?(controller)
      when :update,:edit
        self.can_update?(controller)
      when :destroy
        self.can_delete?(controller)
      when :create,:new
        self.can_write?(controller)
      end
    else
      can_access
    end
  end
  protected

  #var norādīt kontrolierī ka ir pieejamas speciāli actioni
  # allow actions=>{
  #     :show_graphic=>:all,
  #     :remove_links=>:delete
  #     :all_documents=>"director",
  #     :delete_post=>["journalist",:delete,"editor"]
  #}
  # user.can_do_special_action_in_controller?(:delete_post,"cms/post",:actions=>{:delete_posts=>[:delete,"editor"]}
  # Norāda kāda veida pieejas tiesībai atbilst ši darbība [:delete,:write,:update,:read] un ja jekburai tad :all vai lomu(-as)
  #TODO notestēt !action_accessable(izmainīts 05.17.2009)
  def can_access_special_action?(action,controller,options={})
    action_accessable= options && options[:actions] ? options[:actions][action.to_sym] : false
    found=true
    if !action_accessable && Admin::User.area==:system
      #iespējams piekļūta arī actioniem, ja tie ir pieejami viesiem vai publiski
      result=can_access_built_in_actions?(action,options) if options.is_a?(Hash)
      found=result
    elsif (action_accessable.is_a?(String) || action_accessable.is_a?(Symbol)) && action_accessable.to_s=~/all|any|read|write|update|delete/
      result=(action_accessable.to_sym==:all ? self.can_all?(controller) : (action_accessable.to_sym==:any ? self.can_anything?(controller) : self.can_access_simple_special_action?(action_accessable,controller)))
    elsif action_accessable.is_a?(Array)
      result=action_accessable.detect{|access| self.can_access_simple_special_action?(access,controller)} ? true : nil
    else
      result=self.can_access_simple_special_action?(action_accessable)
    end
    return result,found
  end

  def can_access_built_in_actions?(action,options={})
    return self.class.action_in?(action,options[:all]) ||
      self.class.action_in?(action,options[:public]) ||
      (Lolita.config.access :allow, :system_in_public && self.class.action_in?(action,options[:all_public]))
  end
  
  def can_access_simple_special_action? action_accessable,controller=nil
    if action_accessable.to_s=~/read|write|update|delete/
      self.send("can_#{action_accessable}?",controller)
    else
      self.has_role?(action_accessable)
    end
  end

  def all_accesses controller_name="",opt={}
    controller_name=controller_name.to_s.gsub(/^\//,"")
    Admin::User.find_by_sql(["
      SELECT #{opt[:select] || "1"} FROM admin_users
      INNER JOIN roles_users ON roles_users.user_id=admin_users.id
      INNER JOIN accesses_roles ON roles_users.role_id=accesses_roles.role_id
      WHERE accesses_roles.access_id=(SELECT id FROM admin_accesses WHERE name=?)
      #{opt[:permission] ? "AND accesses_roles.allow_#{opt[:permission]}=1" : "" } AND admin_users.id=? LIMIT 1
        ",controller_name,self.id])
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

  def self.except? options
    check_options? options[:permissions][:except],options[:action]
  end
  def self.only? options
    check_options? options[:permissions][:only],options[:action]
  end
  def self.public? options
    check_options? options[:permissions][:public],options[:action]
  end

  def self.action_in? options,area
    perm=options[:permissions][area]
    (perm && perm.is_a?(Hash) ? perm.keys.include?(options[:action]) : (perm.is_a?(Array) ? perm.include?(options[:action]) : nil))
  end

  def self.set_area_and_user(area=nil,user=nil)
    Admin::User.area=area
    Admin::User.current_user=user
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
