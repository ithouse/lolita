# Collect and store controller names. #Admin::Role is linked to accesses and
# each link has different type of permissions (see #Admin::AccessesRoles).
# This model have some useful methods to work with roles and accesses.
class Admin::Access < Cms::Base
  set_table_name :admin_accesses
  has_and_belongs_to_many :roles, :class_name=>"Admin::Role"
 
  # Collect all controller names, so lately roles can be linked with them.
  # For details or controllers collections see Util::System#load_classes.
  def self.collect_all
    old_access_list=Admin::Access.find(:all)
    temp_access=Util::System.load_classes.collect{|table|
      Admin::Access.find_or_create_by_name(table[:name])
    }.compact
    remove_array=old_access_list-temp_access
    Admin::Access.delete(remove_array)
  end

  # Allow do all things for current controller with given role.
  def can_all_with_role(role_name)
    if role_access=get_role_access(role_name)
      role_access.can_all
    end
  end

  # Denay to do anything for current controller with given role.
  def can_nothing_with_role(role_name)
    if role_access=get_role_access(role_name)
      role_access.can_nothing
    end
  end

  # Allow or denay do specific permissions for given controller with given _role_name_.
  def can_with_role_do(role_name,permissions={})
    if role_access=get_role_access(role_name)
      role_access.can permissions
    end
  end

  # Determine whether all things can be done with given _role_name_.
  def can_all? role_name
    if role_access=get_role_access(role_name)
      role_access.can_all?
    end
  end

  # Determine whether nothing can be done with given _role_name_.
  def can_nothing? role_name
    if role_access=get_role_access(role_name)
      role_access.can_nothing?
    end
  end

  # Determine whether given _role_name_ can do what _permission_ says with current controller.
  def can? role_name, permission
    if role_access=get_role_access(role_name)
      role_access.can? permission
    end
  end

  # Determine whether for current access exists role with given _role_name_.
  def has_role?(role_name)
    role=Admin::Role.get_role(role_name,false)
    self.roles.include?(role)
  end

  # Set _role_ to current access with given.
  def has_role (role)
    r=Admin::Role.get_role(role)
    unless self.has_role?(r)
      Admin::AccessesRoles.create(:role_id=>r.id,:access_id=>self.id)
    end
  end


  # Remove given _role_name_ from access roles.
  def has_no_role(role_name)
    role = get_role(role_name)
    if role
      self.roles.delete(role)
    end
  end

  private

  def get_role_access role_name
    role=get_role(role_name)
    Admin::AccessesRoles.find_by_role_and_access(role.id,self.id) if role
  end

  def get_role (role_name)
    Admin::Role.get_role(role_name)
  end
end
