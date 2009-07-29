class Admin::Portal < Cms::Base
  set_table_name :admin_portals
  cattr_accessor :current_portal
  attr_accessor :g_category
  has_one :category, :class_name=>"Cms::Category", :dependent=>:nullify
  has_many :tokens, :class_name=>"Admin::Token", :dependent=>:destroy
  validates_presence_of :domain
  validates_uniqueness_of :domain

  after_save :reset_root

  def design
    parts=self.domain.split(".")
    if parts.size>2 && !self.category
      p=Admin::Portal.find_by_domain(parts[parts.size-2,2].join("."))
      p && p.category ? p.category.design.name : Cms::Design.find_by_root(true).name
    else
      self.category ? self.category.design.name : Cms::Design.find_by_root(true).name
    end
  end

  def good_category
    unless self.g_category
      parts=self.domain.split(".")
      if parts.size>2 && !self.category
        p=Admin::Portal.find_by_domain(parts[parts.size-2,2].join("."))
        self.g_category=p.category if p
      else
        self.g_category=self.category
      end
    end
    self.g_category
  end
  
  private

  def reset_root
    Admin::Portal.find(:all,:conditions=>{:root=>true}).each{|p|
      unless p.id==self.id
        p.update_attributes!(:root=>false)
      end
    } if self.root
  end
end
