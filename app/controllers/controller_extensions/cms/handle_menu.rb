module ControllerExtensions
  module Cms
    module HandleMenu

      # If _object_ form has <em>menu editor</em> than values in that editor
      # need to be handled and this method call Admin::Menu#handle_content_menu_field to do that.
      def handle_menu
        if @menu_record
          menu=Admin::Menu.find_by_id(@menu_record[:menu_id])
          @menu_record=menu.handle_content_menu_field(@menu_record,@object,@config) if menu
        end
      end

    end # module end
  end
end