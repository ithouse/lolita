class Admin::Action < Cms::Base
  set_table_name :admin_actions
  has_one :menu_item, :as => :menuable, :class_name=>"Admin::MenuItem"
end
