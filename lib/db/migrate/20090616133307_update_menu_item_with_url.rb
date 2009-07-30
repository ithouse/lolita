class UpdateMenuItemWithUrl < ActiveRecord::Migration
  def self.up
    add_column :menu_items, :url, :text
  end

  def self.down
    remove_column :menu_items, :url
  end
end
