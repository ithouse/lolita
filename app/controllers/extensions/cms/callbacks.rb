module Extensions
  module Cms
    module Callbacks
      ActionController::Rescue

      def handle_before_create
        if file_id.to_i<1
          @new_object_id=get_temp_id
        else
          @new_object_id=file_id
        end
      end
      
      def handle_after_create
        if menu_item=Admin::MenuItem.find_by_id(params[:menu_item_id])
          menu_item.menuable=@object
          menu_item.save!
        end
        handle_menu
        handle_special_fields
      end

      def handle_after_save
        update_multimedia @object,file_id
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
     
      def handle_function fnc
        self.exacute_managed_callbacks(fnc)
      end

      #beidzas funkcijas
    end
  end
end
