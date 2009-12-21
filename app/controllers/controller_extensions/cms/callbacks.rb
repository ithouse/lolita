module ControllerExtensions
  module Cms
    # For how _callbacks_ works see #Lolita::ManagedCallbacks
    module Callbacks

      # Method used in #Managed. Set instance variable @new_object_id for
      # file uplod, so files will be correct uploaded for new objects.
      # If <tt>temp_id</tt> is already generated than uses it again otherwise generate new one.
      def handle_before_create
        if file_id.to_i<1
          @new_object_id=get_temp_id
        else
          @new_object_id=file_id
        end
      end

      # Used in #Managed. After _object_ has been created it need to be linked with <em>menu_item</em>
      # if there is menu field in form.
      # Also ControllerExtensions::Cms::HandleMenu#handle_menu and
      # ControllerExtensions::Cms::HandleSpecialFields#handle_special_fields is called.
      def handle_after_create
        if menu_item=Admin::MenuItem.find_by_id(params[:menu_item_id])
          menu_item.menuable=@object
          menu_item.save!
        end
        handle_menu
        handle_special_fields
      end

      # Used in #Managed.
      # Update all #Multimedia date that belongs to _object_.
      def handle_after_save
        update_multimedia @object,file_id
      end

      # Used in #Managed to fire events. For callback execution see #Lolita::ManagedCallbacks
      def handle_function fnc
        self.exacute_managed_callbacks(fnc)
      end

    end
  end
end
