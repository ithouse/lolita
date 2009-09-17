class CreateAdminMenuItems < ActiveRecord::Migration
  def self.up
    create_table :admin_menu_items do |t|
      t.string  :name,   :null=>false
      t.string  :menuable_type
      t.integer :menuable_id
      t.string  :alt_text
      t.string  :branch_name
      t.integer :menu_id
      t.integer :parent_id
      t.integer :lft
      t.integer :rgt
      t.boolean :is_published
      t.timestamps 
    end
    add_index :admin_menu_items, :branch_name
    add_index :admin_menu_items, :menu_id
    add_index :admin_menu_items, [:menuable_type,:menuable_id], :name => "menu_item_menuable_index"
    
  end

  def self.down
    drop_table :admin_menu_items
  end
end
