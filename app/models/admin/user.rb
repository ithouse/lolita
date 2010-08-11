# coding:utf-8
require 'digest/sha1'
# Abstract class for users that provide users with authorization methods.
# Other user classes can extend this to get functionalit of this class and store
# users in Lolita's user table.
# ====Example
#     class MyUser < Admin::User
#        set_table_name :admin_users
#     end
#
#     # Now in you controller you can use this user as public user and allow them
#     # authenticate in public area, but you don't have to worry about how password
#     # be encrypted and so on.
#     MyUser.authenticate("login","password") #=> authenticated user
#     MyUser.authenticate("email","password") #=> authenticated user
#     # Also it is possible to grant some privileges for those users, simply adding roles to them
#
#     if my_user.donated?
#       my_user.has_role("contributor")
#     end
#     # And now you can allow them access some special features
#
#     class FunController < ApplicationController
#       allow :actions=>{:games=>"contributors"}
#
#       def games
#         show_plany_games
#       end
#     end
#
# All of this you can get simply extending you user controller with Admin::User.
class Admin::User < Cms::Base
  set_table_name :admin_users
  self.abstract_class = true

  # Protected attributes for password, salt and roles.
  attr_protected :role_ids,:crypted_password,:salt
  # Protected attribute for type.
  attr_protected :type
  # Shortstand for password, that is used when user is created.
  attr_accessor :password
  # Shortstand for old password, thas is used when password is changed.
  attr_accessor :old_password
  attr_reader  :is_admin
  # All users has many roles.
  has_and_belongs_to_many :roles, :class_name=>"Admin::Role"
  
  validates_presence_of :password,                   :if => :password_required?
  validates_length_of   :password, :within => 4..40, :if => :password_required?

  before_save :encrypt_password
  before_save :save_type

  # Accepted arguments:
  # * <tt>:login</tt> - Login name or e-mail for user
  # * <tt>:password</tt> - Password for user
  # * <tt>:allowed_classes</tt> - Array of user classes to allow authenticate via this class
  #                               or Symbol :all if any of user class can authenticate.
  # * <tt>:login_method</tt> - Field used to find user :login, :email or :any - to find by email if
  #                            login name include @ or by login otherwise
  # ====Example
  #     Admin::SystemUser.authenticate("login","password") #=> Only system users can authenticate
  #     Admin::PublicUser.authenticate("login","password",:any) #=> Any type of user can authenticate
  #     Admin::PublicUser.authenticate("login","password",["Admin::PublicUser","Admin::SpecialUser"])
  #     #=> As public users can be authenticated PublicUser and SpecialUser but not SystemUser
  def self.authenticate(login, password, allowed_classes=:none,login_method=:any)
    if login_method==:any
      login.to_s =~ /(^2\d{7}$)|(^[a-z0-9_\.\-]+)@((?:[-a-z0-9]+\.)+[a-z]{2,}$)/i
      if $&.to_s.include?("@")
        self.authenticate_by_email($&,password,allowed_classes)
      else
        self.authenticate_by_login(login,password,allowed_classes)
      end
    elsif login_method==:login
      self.authenticate_by_login(login,password,allowed_classes)
    elsif login_method==:email
      self.authenticate_by_email(login,password,allowed_classes)
    end
  end
  
  # Authenticate user by login name.
  # Accepted arguments:
  # * <tt>login</tt> - login name that is used to find user.
  # * <tt>password</tt> - password that is used to authenticate user, that is found.
  # * <tt>allowed_classes</tt> - Array of user classes that is used to find user by login.
  #                       Default is +none+ to use current user class. See #authenticate for details.
  def self.authenticate_by_login(login, password,allowed_classes=:none)
    self.authenticate_unknown_user(login,password,"login",allowed_classes)
  end

  # Authenticate user by e-mail address.
  # Accepted arguments:
  # * <tt>email</tt> - e-mail address used to find user.
  # * <tt>password</tt> - password used to authenticate founded user.
  # * <tt>allowed_classes</tt> - User classes that are uses for identification of user. Default :none. See #authenticate.
  def self.authenticate_by_email(email, password,allowed_classes=:none)
    self.authenticate_unknown_user(email,password,"email",allowed_classes)
  end

  # Authenticate user by remember +token+ and return right class user object
  # if +token+ exists or false if not.
  def self.authenticate_by_cookies(token)
    self.find_unknown_user(:first,["remember_token=?",token])
  end

  # Deperecated!
  def self.access_to_area?(user,area=false)
    true #FIXME
  end

  # Used to allow user authenticate in controller.
  # In *Lolita* used in Lolita::Authorization::ControllerClassMethods#allow.
  # Get authentication options and if its matches any of conditions than set
  # current user area and #current_user for Admin::User.
  # Accepted options:
  # * <tt>:roles</tt> - Role name or Array with role names, used to check if role has access to controller.
  # * <tt>:action</tt> - Action name to which need access.
  # * <tt>:controller</tt> - Controller name in which method is in.
  # * <tt>:user</tt> - User that tries to access method. Need to be a child class of Admin::User.
  # * <tt>:permissions</tt> - Hash of all kind of permissions that is supported by #allow method:
  #   * <tt>:public</tt> - public methods
  #   * <tt>:system</tt> - system methods
  #   * <tt>:all</tt> - Deprecated, same as :system
  #   * <tt>:public_system</tt> - Public system methods
  #   * <tt>:actions</tt> - Special kind of methods Hash. See Lolita::Authorization::ControllerClassMethods#allow for details.
  # If any of conditions matches then true is returned otherwise false.
  def self.authenticate_in_controller options={}
    options[:permissions]||={}
    set_area_and_user()
    allowed=if action_in?(options,:public)
      set_area_and_user(:public,options[:user])
    elsif !action_in?(options,:all_public) && options[:user] && options[:user].is_a?(Admin::SystemUser)
      set_area_and_user(:system,options[:user])
      options[:user].is_admin? || (action_in?(options,:all) || action_in?(options,:system)) || (options[:user].has_access?(options))
    elsif options[:user] && (action_in?(options,:all_public) || options[:user].has_access?(options))
      set_area_and_user(:public_system,options[:user])
    end
    return allowed
  end

  # Set current user that may be used to get current request user or to test with
  # this user as current request user.
  def self.current_user=(user)
    @current_user=user
  end

  # Getter for current user.
  def self.current_user
    @current_user
  end

  # Set current user area.
  def self.area=(area)
    @area=area
  end

  # Get current user area.
  def self.area
    @area
  end

  # Generate temp password with capital leters numbers and downcase letters.
  # Can be used to genereate random string for any purpose.
  # String length is generated from +len+.
  def self.temp_password len=20
    new_pasw=""
    1.upto(len) do
      posibilities=[rand(10)+48,rand(26)+65,rand(26)+97]
      new_pasw<<posibilities[rand(3)]
    end
    new_pasw
  end

  # Used to encrypt password with salt, that is 20 random symbols string, but
  # may be used to encrypt any other simple string with other meaningless one.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Reset password for user, before user change it.
  # Current password is changed to #temp_password and user is given 3 days to change it.
  # Also creates +renew_password_hash+ for identifying password.
  def reset_password
    self.update_attributes!(
      :reset_password_expires_at=>3.days.from_now
    )
    self.update_attributes!(:renew_password_hash=>self.reseted_password_hash)
  end


  # Genereate unique SHA1 hash string, so user can click on link in e-mail
  # or in other way get to change password dialog with this identifier.
  def reseted_password_hash
    Digest::SHA1.hexdigest("--#{self.crypted_password}--#{self.email}--#{self.salt}--#{self.reset_password_expires_at}--")
  end

  # Find user using #reseted_password_hash and +reset_password_expires_at+
  # if user asked for password change and it is not too late for doing that
  # than return user object, otherwise nil.
  # Method need to receive _id_ that is string stored in +renew_password_hash+.
  def self.change_password_for id
    self.find_unknown_user(:first,
      ["type=? AND NOT reset_password_expires_at IS NULL AND
        reset_password_expires_at>=? AND renew_password_hash=?",
        self.to_s,Time.now,id]
    )
  end

  # Renew user password with given _pass_
  # Create new password and is meant to call when user change password.
  # User data is updated with _pass_ and disabled possibility to change password
  # again with unique hash from #reseted_password_hash.
  def renew_password(pass,confirmation=nil)
    attr={
      :password=>pass,
      :reset_password_expires_at=>nil,
      :renew_password_hash=>nil
    }
    attr.merge!(:password_confirmation=>confirmation) if confirmation
    self.update_attributes(attr)
  end

  # Determine whether or not password must be changed, depending on password
  # expires date.
  def must_change_password?
    self.reset_password_expires_at
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  # Check if user is authenticated with given _password_, by comparing
  # crypted password with this password after #encrypt
  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  # Determine whether remember token is expired or not.
  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at
  end

  # By calling +remember_me+ it is possible to store user as logged in between
  # browsing session, but automaticly loging in must be enabled for different
  # kind of users.
  def remember_me
    self.remember_token_expires_at = 2.weeks.from_now.utc
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end

  # Getter for froms with <i>user</i> object, for checkbox field, to determine whether
  # user is remembered or not.
  def remember_user
    remember_token?
  end

  # Contrawise #remember_me.
  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end

  # Return +true+ if user has <i>administrator</i> role.
  def is_admin?
    @is_admin||=[self.has_role?(Admin::Role.admin)]
    @is_admin[0]
  end

  # Remove role from user roles, _role_name_ can by any of accepted types see Admin::Role#get_role
  def has_no_role role_name
    if role=Admin::Role.get_role(role_name,false)
      self.roles.delete(role)
    end
  end

  # Add role to user if user not already have it. For accepted type of _role_name_ see Admin::Role#get_role.
  def has_role role_name
    role=Admin::Role.get_role(role_name)
    unless self.has_role?(role)
      self.roles<<role if (role.name==Admin::Role.admin && self.class==Admin::SystemUser) || role.name!=Admin::Role.admin
    end
  end

  # Check if user has role or not. For accepted types of _role_name_ see Admin::Role#get_role.
  def has_role?(role_name)
    role=Admin::Role.get_role(role_name,false)
    self.roles.include?(role)
  end

  # Determine whether user has access to special roles or call #can_access_action? when no roles
  # is specified. Acceptes _options_ Hash. Accepted hash options is:
  # * :roles
  # * :action
  # * :controller
  # * :permissions
  # For details of what those options mean see #authenticate_in_controller.
  def has_access? options={}
    roles=[options[:roles]] if options[:roles].is_a?(String)
    if roles && !roles.empty?
      Admin::User.find_by_sql(["
        SELECT #{self.class.table_name}.id FROM #{self.class.table_name}
        INNER JOIN roles_users ON roles_users.user_id=#{self.class.table_name}.id
        WHERE roles_users.role_id IN
          (SELECT id FROM admin_roles WHERE name IN (?)) AND roles_users.user_id=?
        LIMIT 1",roles,self.id]).empty? ? false : true
    else
      return self.can_access_action?(options[:action],options[:controller],options[:permissions])
    end
  end

  # Check if user can do all things with given _controller_name_. See #can_what? for details.
  def can_all? controller_name
    actions=can_what? controller_name
    actions[:read] && actions[:write] && actions[:update] && actions[:delete]
  end

  # Check if user can do anything with given _controller_name_ controller. See #can_what? for details.
  def can_anything? controller_name
    actions=can_what? controller_name
    actions[:read] || actions[:write] || actions[:update] || actions[:delete]
  end

  # Check if user can do what _permission_ says with _controller_name_. See #can_what for details.
  def can? controller_name,permission
    all_accesses(controller_name,{:permission=>permission}).empty? ? false : true
  end

  # Check if user can do deleting in _controller_name_.
  def can_delete? controller_name
    can? controller_name, :delete
  end

  # Check if user can do reading in _controller_name_.
  def can_read? controller_name
    can? controller_name, :read
  end

  # Check what user can do with _controller_name_ and returns hash with
  # permission names and as value of those permission is true if action is
  # available or false if not.
  # There are four possible permissions:
  # * <tt>read</tt> - for reading in controller.
  # * <tt>write</tt> - for writing in controller.
  # * <tt>update</tt> - for changing in controller.
  # * <tt>delete</tt> - for deleting in controller.
  # For details how to use those in controllers see Lolita::Authorization::ControllerClassMethods#allow.
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

  # Check if user can do writing in _controller_name_.
  def can_write? controller_name
    can? controller_name, :write
  end

  # Chekc if use can do updating in _controller_name_.
  def can_update? controller_name
    can? controller_name, :update
  end

  # Check if user can access specific _action_ in _controller_ with given _options_.
  # Try to find if this action is specified in _options_ in :actions Hahs, if nothing is
  # found than do simple matching with default #Lolita action names and CRUD names.
  # There are following method that is accessable by defautl with such access rights:
  # * <tt>with read</tt> - list, read, open, index
  # * <tt>with update</tt> - update, edit
  # * <tt>with delete</tt> - destroy
  # * <tt>with write</tt> - create, new
  # For details of how to specify special rights see Lolita::Authorization::ControllerClassMethods#allow.
  def can_access_action?(action,controller,options={})
    can_access,found=self.can_access_special_action?(action,controller,options)
    unless !action || found 
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


  # If class of user is unknown, or need to allow authenticate many users than
  # this method is used, to find users and then try to authenticate it.
  # Require _login_ of user, that may be e-mail as well, _password_ and _method_
  # that is used as field name which is used to find user, and optionaly
  # _allowed_classes_ may be passed, for details see Admin::User#authenticate.
  # ====Example
  #     Admin::User.authenticate_unknown_user("system_user_1","password","login")
  #     #=> Return, for example, Admin::SystemUser object
  def self.authenticate_unknown_user(login,password,method,allowed_classes=:none)
    conditions=["#{method}=? AND type IN (?)",login,user_class_types(allowed_classes)]
    user=self.find_unknown_user(:first,conditions)
    user && user.authenticated?(password)  ? user : false
  end

  # As Admin::User is abstract class, then using find method on Admin::User will
  # return object with class name Admin::User, but mostly need to get real class of object
  # that is stored in +type+ field, and need to operate only with those kind of type users.
  # Method +find_unknonw_user+ allow to user any of user classes or Admin::User to find
  # user and get it as real class object.
  # There are to arguments accepted, _find_what_, that can be :all, or :first, but any other
  # than :all will be perceived as :first. And conditions, that may by any kind of conditions
  # that is acceptable for ActiveRecord::Base#find.
  # Method uses DB connection directly so find method wouldn't be call or other chain methods.
  # After record is found than it is transformet in correct user class object using
  # Cms::Base#new_object_from_record.
  # ====Example
  #   Admin::User.find_unknown_user(:first,["type IN (?)",["Admin::SystemUser","OtherUser"]]
  #   #=> find first user that has type Admin::SystemUser or OtherUser and return instance of that class.
  def self.find_unknown_user(find_what=:all,conditions=nil)
    sql=ActiveRecord::Base.connection
    conditions=sanitize_sql(conditions).to_s
    record=sql.send(find_what==:all ? :select_all : :select_one,
      "SELECT * FROM #{self.table_name} #{conditions.size>0 ? "WHERE #{conditions}" : ""}"
    )
    if record
      if record.is_a?(Array)
        record.collect{|r| self.new_object_from_record(r, r['type'])}
      else
        self.new_object_from_record(record,record['type'])
      end
    else
      nil
    end
  end

  protected

  # Collect users classes that is available.
  # Method accepts following _allowed_classes_:
  # * <tt>:none</tt> - Use current user class, can be used when find or authentication
  #                    methods is called on real user class, like Admin::SystemUser.
  # * <tt>:all</tt> - Collect all classes from DB and create Array of them, useful when
  #                   need to find user by remember_token.
  # * <tt>Array</tt> - Array of class names that need to be used in find or authentication methods.
  #                    Useful, for example, when need to authenticate public users, that have different classes.
  def self.user_class_types(allowed_classes=:none)
    if allowed_classes.is_a?(Array)
      allowed_classes.collect{|c| c.to_s}
    elsif allowed_classes==:all
      self.find_by_sql("SELECT type FROM #{table_name} GROUP BY type").collect{|u| u["type"]}
    else
      self.to_s
    end
  end
  
  # Detect if user can access controller action, check if it is a built in action when
  # no actions is speficied. See Lolita::Authorization::ControllerClassMethods#allow, for details of how
  # actions can be passed from controller.
  # _Action_ and _controller_ need to be passed, and following _options_ are accepted:
  # * <tt>:actions</tt> - Hash of actions as keys and values determine what kind of access
  #                       user need to access that action.
  # * <tt>:permissions</tt> - Hash of areas (:public,:system,:public_system), and values are Arrays
  #                           of method that are accessable for those areas.
  def can_access_special_action?(action,controller,options={})
    action_accessable= options && options[:actions] ? options[:actions][action.to_sym] : false
    found=true
    if !action_accessable && Admin::User.area==:system
      #iespējams piekļūta arī actioniem, ja tie ir pieejami viesiem vai publiski

      result=can_access_built_in_actions?(:action=>action,:permissions=>options) if options.is_a?(Hash)
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

  # Fallback method for #can_access_special_action? to detect if accessed action is
  # built in, so system user can access :public or :system actions, because they are
  # accessable for all system users, or :public_system if configuration allows it
  # (to allow system users by default access :public_system in configuration set
  # access.allow.system_in_public to _true_).
  def can_access_built_in_actions?(options={})
    return self.class.action_in?(options,:system) ||
      self.class.action_in?(options,:all) || 
      self.class.action_in?(options,:public) ||
      (Lolita.config.access(:allow, :system_in_public) && self.class.action_in?(options,:public_system))
  end

  # Determine whether user can has access to specific kind of permission or has role.
  # _action_accessable_ can be role or access name and _controler_ need to be specified only
  # when _action_accessable_ is access name.
  # For details see #has_role? and #can_what?
  def can_access_simple_special_action? action_accessable,controller=nil
    if action_accessable.to_s=~/read|write|update|delete/
      self.send("can_#{action_accessable}?",controller)
    else
      self.has_role?(action_accessable)
    end
  end

  # Find all accesses for user for specific _controller_name_, also
  # _opt_ can be passed and it accepts to keys:
  # * <tt>:select</tt> - what been returned from select statement, default 1
  # * <tt>:permission</tt> - permission name to return if need to check specific type of permission.
  # Method return ActiveRecord::Base object.
  def all_accesses controller_name="",opt={}
    controller_name=controller_name.to_s.gsub(/^\//,"")
    Admin::User.find_by_sql(["
      SELECT #{opt[:select] || "1"} FROM #{self.class.table_name}
      INNER JOIN roles_users ON roles_users.user_id=#{self.class.table_name}.id
      INNER JOIN accesses_roles ON roles_users.role_id=accesses_roles.role_id
      WHERE accesses_roles.access_id=(SELECT id FROM admin_accesses WHERE name=?)
      #{opt[:permission] ? "AND accesses_roles.allow_#{opt[:permission]}=1" : "" } AND #{self.class.table_name}.id=? LIMIT 1
        ",controller_name,self.id])
  end

  # Simple method to compare Array or Symbol or String with action name.
  # ====Example
  #     check_options?([:a,:b],"a"] #=> true
  #     check_options?(["a"],"a"] #=> false
  #     check_options?("a","a") #=>true
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

  # Deprecated!
  def self.except? options
    check_options? options[:permissions][:except],options[:action]
  end

  # Deprecated!
  def self.only? options
    check_options? options[:permissions][:only],options[:action]
  end

  # Check if action is indicated as public action.
  def self.public? options
    check_options? options[:permissions][:public],options[:action]
  end

  # Check if action is in specific _area_ in _options_ Hash, where keys denotes areas.
  def self.action_in? options,area
    perm=options[:permissions][area]
    (perm && perm.is_a?(Hash) ? perm.keys.include?(options[:action]) : (perm.is_a?(Array) ? perm.include?(options[:action]) : nil))
  end

  # Set _user_ and _area_, used in Admin::User#authenticate_in_controller
  def self.set_area_and_user(area=nil,user=nil)
    Admin::User.area=area
    Admin::User.current_user=user
    return true
  end

  # Encrypt password when saving user.
  def encrypt_password
    return if password.blank?
    self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{email}--") if new_record?
    self.crypted_password = encrypt(password)
  end

  # Determine whether password is blank or not.
  def password_required?
    !password.blank?
  end

  private

  def save_type
    self.type=self.class.to_s
  end
end
