# 
# SIA ITHouse
# Artūrs Meisters
# 11.03.2008 11:23
module ITHouse
  module Acts #:nodoc:
    module ContentItem #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)              
      end
      module ClassMethods
        def acts_as_content_item
         # acts_as_content_item_objects=Array.new();
          include ITHouse::Acts::ContentItem::InstanceMethods
          extend ITHouse::Acts::ContentItem::ClassMethods
        end
        
        def setup_content(params=nil,form="")
          if form
            obj=self.new(params[form.to_sym])
          else
            obj=self.new
          end
          if params && params[:menu_item_id]
            obj.temp_id=params[:menu_item_id]
          end
          obj
        end
      end

      # This module provides instance methods for an enhanced acts_as_content_item mixin. Please see the README for background information, examples, and tips on usage.
      module InstanceMethods
       
        def temp_id= (val)
          @temp_id = val
        end
        def temp_id
          @temp_id
        end
        # On creation, automatically add the new node to the right of all existing nodes in this tree.
        def after_create # already protected by a transaction
          if self.temp_id
            mi=MenuItem.find(self.temp_id)
            mi.menuable_id=self.id
            mi.menuable_type=self.class.to_s
            mi.save
          end
        end
       
        # On destruction, delete all children and shift the lft/rgt values back to the left so the counts still work.
        def before_destroy # already protected by a transaction
          #does nothing yet :)
        end
        
        def content_menu_item
          Menu.find_by_menu_name('content').menu_items.find(:all, :conditions=>"menuable_id=#{self.id}").first
        end
        
      end
    end
  end
 
end
