class CreateAdminMenus < ActiveRecord::Migration
  def self.up
    create_table :admin_menus do |t|
      t.string    :menu_name,   :null=>false
      t.string    :menu_type,   :null=>false
      t.string    :module_name
      t.string    :module_type , :null=>false
    end
  end

  def self.down
    drop_table :admin_menus
  end
end
