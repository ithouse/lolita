module Extensions::CommonReflections
  acts_as_content_item
  has_many :menu_items, :as=>:menuable, :dependent=>:nullify
  has_one :meta_data, :as => :metaable, :dependent => :destroy
end
