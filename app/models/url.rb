class Url < Cms::Base
   belongs_to :addressable, :polymorphic=>true
   has_many :menu_items, :class_name=>"Admin::MenuItem", :as=>:menuable
end
