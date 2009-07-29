class Admin::AccessesRoles < Cms::Base
  set_table_name 'accesses_roles'
   
  def self.find_by_role_and_access role,access
    self.find(:first,
      :select=>"id,allow_read,allow_write,allow_update,allow_delete",
      :conditions=>["role_id=? AND access_id=?",role,access]
    )
  end

  def can_all
    self.allow_write=true
    self.allow_read=true
    self.allow_update=true
    self.allow_delete=true
    self.save!
  end

  def can_nothing
    self.allow_write=false
    self.allow_read=false
    self.allow_update=false
    self.allow_delete=false
    self.save!
  end

  def can_what?
    {:read=>self.allow_read,:write=>self.allow_write,:update=>self.allow_update,:delete=>self.allow_delete}
  end
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
  def can_all?
    self.allow_write && self.allow_read && self.allow_update && self.allow_delete
  end
  def can_nothing?
    !self.allow_write && !self.allow_read && !self.allow_update && !self.allow_delete
  end
  def writeable
    self.allow_write
  end
  def writeable=(value)
    self.allow_write=value
  end

  def readable
    self.allow_read
  end
  def readable=(value)
    self.allow_read=value
  end

  def updateable
    self.allow_update
  end
  def updateable=(value)
    self.allow_update=value
  end

  def deleteable
    self.allow_delete
  end
  def deleteable=(value)
    self.allow_delete=value
  end
end
