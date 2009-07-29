module Extensions
  module Cms
    module Callbacks
      ActionController::Rescue

      def handle_before_create
        if picture_id.to_i<1
          @new_object_id=get_temp_id
        else
          @new_object_id=picture_id
        end
      end
      
      def handle_after_create
        if has_picture_id?
          update_uploaded_pictures @object,picture_id
        end
        if has_file_id?
          update_uploaded_files @object,file_id
        end
        if menu_item=Admin::MenuItem.find_by_id(params[:menu_item_id])
          menu_item.menuable=@object
          menu_item.save!
        end
        #handle_has_many_relation true
        #handle_has_many_polimorphic_relation true
        handle_menu
        #handle_external_object_relations
        handle_special_fields
      end

      # Funkcija, kas atbild par to, lai varētu ievietot apakšklasēs funkcijas, kas tiktu
      # izsauktas pirms kādas attiecīgās darbības, piemēram
      # ievietojam kontrolierī
      # User < Managed
      # def before_edit
      #   ......
      # end
      # šī funkcija tiks izsaukta pirms edit, funkcijas, taču tai būs pieejami visi mainīgie
      # tādī kā @config, @all u.c.
      def handle_before_functions fnc,*args
        handle_function("before_#{fnc}",args[0])
        handle_function("before_save",args[0]) if fnc=='create' || fnc=='update'
        handle_function("before_open",args[0]) if fnc=="new" || fnc=="edit"
      end

      def handle_after_functions fnc, *args
        handle_function("after_#{fnc}",args[0])
        handle_function("after_save",args[0]) if fnc=='create' || fnc=='update'
        handle_function("after_open",args[0]) if fnc=="new" || fnc=="edit"
      end

      def handle_function fnc, *args
        self.send(fnc) if self.respond_to?(fnc,true)
      end

      #beidzas funkcijas
    end
  end
end
