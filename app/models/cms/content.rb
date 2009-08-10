class Cms::Content < Cms::Manager
  self.abstract_class = true

  acts_as_content_item
  has_many :menu_items, :as=>:menuable, :dependent=>:nullify, :class_name=>"Admin::MenuItem"
  
    class << self
    def find_related_menu_item menu_name, id
      element=self.find_by_id(id)
      if element
        namespace=self.to_s.split("::").first
        self.reflections.each{|name,reflection|
          if reflection.macro==:belongs_to
            temp_menu_item=Admin::Menu.find_by_menu_name(menu_name).menu_items.find(:first,
              :conditions=>["menuable_type=? AND menuable_id=? AND is_published=1",
                "#{namespace}::#{name.to_s.camelize}",
                element.send("#{name}_id")
              ]
            )
            if temp_menu_item && temp_menu_item.level>0 #TODO vajadzētu visiem līmeņiem
              return temp_menu_item
            end
          end
        }
      end
      return nil
    end
    
  end
end