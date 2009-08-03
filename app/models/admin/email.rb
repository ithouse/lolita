class Admin::Email < Cms::Manager
  set_table_name :admin_emails
  belongs_to  :user,  :class_name=>"Admin::User"

  validates_format_of :address,
    :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i,
    :message => 'email must be valid'
  validates_uniqueness_of :address
  named_scope :starts_with, lambda{|name|
    {:conditions=>["`admin_emails`.address LIKE ?","#{name}%"],:limit=>5}
  }
  named_scope :ends_with, lambda{|name|
    {:conditions=>["`admin_emails`.address LIKE ?","%#{name}"],:limit=>5}
  }
  named_scope :in_address, lambda{|name|
    {:conditions=>["`admin_emails`.address LIKE ?","%#{name}%"],:limit=>5}
  }
  before_save :check_status
  before_destroy :destroy_temp_user
  
  def emails=(values)
    self.class.create_emails(values)
  end

  def self.emails=(values)
    create_emails(values)
  end
  
  def created
    self.created_at.strftime("%Y.%m.%d")
  end

  private

  def self.create_emails(values)
    values=values.split(",") if values.is_a?(String)
    values.each{|address|
      Admin::Email.create!(:address=>address) unless Admin::Email.find_by_address(address)
    }
  end
  
  def check_status
    if !self.status
      self.status=1
    end
  end
  def destroy_temp_user
    self.user.destroy if self.user && !self.user.registered?
  end
end
