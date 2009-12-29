# Abstract class that add reflection with menu items and class method working with menu items.
# Is subclass of #Cms::Manager.
class Cms::Content < Cms::Manager
  self.abstract_class = true
  has_many :menu_items, :as=>:menuable, :dependent=>:nullify, :class_name=>"Admin::MenuItem"
  
  class << self
    def find_related_menu_item menu_name, id # :nodoc:
      element=self.find_by_id(id)
      result = []
      if element
        self.reflections.each{|name,reflection|
          if reflection.macro==:belongs_to
            temp_menu_items=Admin::Menu.find_by_menu_name(menu_name).menu_items.find(:all,
              :conditions=>["menuable_type=? AND menuable_id=? AND is_published=1",
                reflection.class_name,
                element.send("#{name}_id")
              ]
            )
            result += temp_menu_items.collect!{|item| item.level>0 ? item : nil}.compact!
          end
        }
      end
      return result
    end

  end

end