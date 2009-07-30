class CreateMenus < ActiveRecord::Migration
  def self.up
    create_table :menus do |t|
      t.string    :menu_name,   :null=>false
      t.string    :menu_type,   :null=>false
      t.string    :module_name
      t.string    :module_type , :null=>false
      t.boolean   :has_images
    end
    insert("INSERT INTO menus (menu_name,menu_type,module_name,module_type) VALUES('Admin','app','admin','app')")
    insert("INSERT INTO menus (menu_name,menu_type,module_name,module_type) VALUES('Cms','app','cms','app')")
    insert("INSERT INTO menus (menu_name,menu_type,module_name,module_type) VALUES('Saturs','web','cms','web')")
  end

  def self.down
    drop_table :menus
  end
end
