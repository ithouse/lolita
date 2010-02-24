# This is a reflection class for roles and accesses. This class provide
# role and access link with 4 different permissions: write, read, update and delete.
# Class provide some useful methods to operating with permissions for roles-access
# link.
class Admin::AccessesRoles < Cms::Base
  set_table_name 'accesses_roles'

  # Find access role object by _role_ ID and _access_ ID.
  def self.find_by_role_and_access role,access
    self.find(:first,
      :select=>"id,allow_read,allow_write,allow_update,allow_delete",
      :conditions=>["role_id=? AND access_id=?",role,access]
    )
  end

  # Set all permissions to +true+, and save them.
  def can_all
    self.allow_write=true
    self.allow_read=true
    self.allow_update=true
    self.allow_delete=true
    self.save!
  end

  # Set all permissions to +false+, and save them.
  def can_nothing
    self.allow_write=false
    self.allow_read=false
    self.allow_update=false
    self.allow_delete=false
    self.save!
  end

  # Return Hash of what role can do with given access. Keys are permission names
  # and values are +true+ or +false+.
  def can_what?
    {:read=>self.allow_read,:write=>self.allow_write,:update=>self.allow_update,:delete=>self.allow_delete}
  end

  # Return +true+ if _permission_ is allowed for current role-access link.
  def can? permission=nil
    if [:read,:write,:update,:delete].include?(permission.to_sym)
      case permission.to_sym
      when :read
        self.allow_read
      when :write
        self.allow_write
      when :update
        self.allow_update
      when :delete
        self.allow_delete
      end
    end
  end

  # Receive _permissions_ Hash with permissions as key and values +true+ or +false+
  # and set them to current link and save it.
  def can permissions={}
    permissions.each{|key,value|
      #value=value=='true' || value==true ? true : nil
      case key.to_sym
      when :read
        self.allow_read=value
      when :write
        self.allow_write=value
      when :update
        self.allow_update=value
      when :delete
        self.allow_delete=value
      end
    }
    self.save
  end

  # Check if everything can be done for role with given access.
  def can_all?
    self.allow_write && self.allow_read && self.allow_update && self.allow_delete
  end

  # Determine whether is nothing been done with role-access link.
  def can_nothing?
    !self.allow_write && !self.allow_read && !self.allow_update && !self.allow_delete
  end

  # Determine whether link is writable.
  def writeable
    self.allow_write
  end

  # Set link as writable or not.
  def writeable=(value)
    self.allow_write=value
  end

  # Determine whether link is readble
  def readable
    self.allow_read
  end

  # Set link as readable or not.
  def readable=(value)
    self.allow_read=value
  end

  # Determine whether link is updatable.
  def updateable
    self.allow_update
  end

  # Set link as updatable or not.
  def updateable=(value)
    self.allow_update=value
  end

  # Determine whether link is deletable.
  def deleteable
    self.allow_delete
  end

  # Set link as deletable or not.
  def deleteable=(value)
    self.allow_delete=value
  end
end
