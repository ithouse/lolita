module Extensions
  module Cms
    module HandleMenu
      
      def handle_menu
        if @menu_record
          menu=Admin::Menu.find_by_id(@menu_record[:menu_id])
          @menu_record=menu.handle_content_menu_field(@menu_record,@object,@config) if menu
        end
      end

    end # module end
  end
end