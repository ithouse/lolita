class Admin::Role < Cms::Base
  ADMIN="administrators"
  set_table_name :admin_roles
  
  has_and_belongs_to_many :users, :class_name=>"Admin::User"
  has_and_belongs_to_many :accesses, :class_name=>"Admin::Access"
  #has_many :external_objects, :dependent=>:destroy
  validates_uniqueness_of   :name
  belongs_to :authorizable, :polymorphic => true
  validates_presence_of :name

  def self.admin
    Admin::Role::ADMIN
  end
  
  def has_user? user
    self.users.find_by_login(user)
  end
    
  def has_access? access
    self.accesses.find_by_name(access)
  end
end
