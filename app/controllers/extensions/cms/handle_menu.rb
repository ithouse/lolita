module Extensions
  module Cms
    module HandleMenu
      def handle_menu
        if @menu_record 
          #Ja ir izvēlēta māja tad menu ir mājas menu ja ne tad visu māju menu
          menu=Admin::Menu.find_by_id(@menu_record[:menu_id])
          if menu
            #Sameklēju iepriekšējo menu_itemu
            old_item=Admin::MenuItem.find(:first,:conditions=>["menuable_type=? and menuable_id=? and menu_id=?",@config[:object_name].camelize,@object.id,menu.id])
            #sameklēju to menu itemu kurš ir izvēlēts kokā
            if Admin::MenuItem.exists?(@menu_record[:branch])
              new_parent=Admin::MenuItem.find(@menu_record[:branch])
            else
              if @menu_record[:branch].to_i>0 || (@menu_record[:branch].to_i<1 && @menu_record[:new].to_s.size>0)
                new_parent=menu.menu_items.first.root
                @menu_record[:dir]='e'
              end
            end
            #ja nekas nav izvēlēts tad tālāk nav vērts neko darīt
            return unless new_parent
            #Ja ir ierakstits nosaukums tad tiek veidots jauns menu items
            if @menu_record[:new].size>0
              mi=Admin::MenuItem.create(:name=>@menu_record[:new],:menuable_type=>@config[:object_name].camelize,:menuable_id=>@object.id,:menu_id=>menu.id,:is_published=>true)
              case @menu_record[:dir]
              when 's'
                mi.move_to_right_of(new_parent)
              when 'n'
                mi.move_to_left_of(new_parent)
              when 'e'
                mi.move_to_child_of(new_parent)
              end
            else
              #Ja nav jauns izvēlēts tad ir jāieraksta izvēlētajā zarā
              #Ja gadījumā ir bijis jau iepriekš šis elements kkur piesaistīts tad no turienes viņu aizvāc
              #Pielieku izvēlētajam zaram klāt elementu, piemēram 'News',11
              new_parent.change_content(@config[:object_name].camelize,@object.id,old_item ? old_item.is_published : true)
            end
            #Es domāju ka jānoņem ir jebkurā gadījumā ja ir bijis vecais elements
            if old_item && old_item!=new_parent
              old_item.change_content(nil,0)
            end
            if (old_item && old_item!=new_parent) || (!old_item && @menu_record[:new].size<1) || @menu_record[:new].size>0
              menu.save
            end
          end
        end
      end
    end # module end
  end
end