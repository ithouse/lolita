class AddNotMainMenuFieldToMenuItem < ActiveRecord::Migration
  def self.up
    add_column :menu_items, :not_main_menu, :boolean
  end

  def self.down
    remove_column :menu_items, :not_main_menu
  end
end
