# Role model is used to store roles and link them with users in #Admin::User and
# with accesses in #Admin::Access. There are one built in role "administrator".
# Role cannot be created without _name_ and _name_ must be unique.
# There are has_and_belongs_to_many associations that uses association tables,
# that are create when you setup Lolita.
class Admin::Role < Cms::Base
  ADMIN="administrator"
  set_table_name :admin_roles
  
  has_and_belongs_to_many :users, :class_name=>"Admin::User"
  has_and_belongs_to_many :accesses, :class_name=>"Admin::Access"
  
  validates_uniqueness_of   :name
  belongs_to :authorizable, :polymorphic => true
  validates_presence_of :name

  # Shorter way to get admin role name.
  def self.admin
    Admin::Role::ADMIN
  end

  # Determine whether or not role has _user_ that may be login or e-mail.
  def has_user? user
    if user.to_s =~ /(^2\d{7}$)|(^[a-z0-9_\.\-]+)@((?:[-a-z0-9]+\.)+[a-z]{2,}$)/i
      self.users.find_by_email($&)
    else
      self.users.find_by_login(user)
    end
  end

  # Determine whether role is linked with _access_ that is controller name.
  def has_access? access
    self.accesses.find_by_name(access)
  end

  def can_what_with_access? access
    ra_link=Admin::AccessesRoles.find_by_role_and_access(self.id,access.id)
    ra_link ? ra_link.can_what? : {}
  end
  # Get Admin::Role object by passing _role_ as Fixnum, String, Symbol or Admin::Role.
  # Also _default_create_ can be passed, to forbid role creating when
  # String or Symbol is passed, default is true, so if role with that name
  # doesn't exists that it will be created.
  # ====Example
  #     Admin::Role.get_role(1) #=> Try to find role with ID 1
  #     Admin::Role.get_role("administrator") #=> Find or create role with name "administrator"
  #     Admin::Role.get_role(:editor,false) #=> Try to find role with name "edoitor", but no create if can't.
  #     Admin::Role.get_role(Admin::Role.find(:first)) #=> Return role passed as argument.
  def self.get_role(role,default_create=true)
    if role.is_a?(Fixnum)
      Admin::Role.find_by_id(role)
    elsif role.is_a?(String) || role.is_a?(Symbol)
      if default_create
        Admin::Role.find_or_create_by_name(role.to_s)
      else
        Admin::Role.find_by_name(role.to_s)
      end
    elsif role.is_a?(Admin::Role)
      role
    end
  end
end
