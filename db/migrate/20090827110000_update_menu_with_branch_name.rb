class UpdateMenuWithBranchName < ActiveRecord::Migration
  def self.up
    begin
    remove_column :menu_items,:not_main_menu
    rescue;end
    remove_column :menu_items, :url
    add_column :menu_items, :branch_name, :string
  end

  def self.down
    begin
    add_column :menu_items,:not_main_menu,:boolean
    rescue;end
    add_column :menu_items, :url, :string
    remove_column :menu_items, :branch_name
  end
end