class CreateMenuItems < ActiveRecord::Migration
  def self.up
    create_table :menu_items do |t|
      t.string  :name,   :null=>false
      t.string  :page_title
      t.string  :alt_text
      t.string  :menuable_type
      t.integer :menuable_id
      t.integer :menu_id
      t.integer :parent_id
      t.integer :lft
      t.integer :rgt
      t.boolean :is_published
      t.timestamps 
    end
    insert("INSERT INTO menu_items (name,menu_id,lft,rgt) VALUES('Admin',1,1,20)")
    insert("INSERT INTO menu_items (name,menu_id,lft,rgt) VALUES('Saturs',3,1,2)")
    insert("INSERT INTO menu_items (name,menuable_type,menuable_id,menu_id,parent_id,lft,rgt)"+
           "VALUES('Lietotāji','Admin::Action',1,1,1,2,5)")
    insert("INSERT INTO menu_items (name,menuable_type,menuable_id,menu_id,parent_id,lft,rgt)"+
           "VALUES('Lomas','Admin::Action',2,1,1,6,9)")
    insert("INSERT INTO menu_items (name,menuable_type,menuable_id,menu_id,parent_id,lft,rgt)"+
           "VALUES('Pieejas','Admin::Action',3,1,1,10,11)")
    insert("INSERT INTO menu_items (name,menuable_type,menuable_id,menu_id,parent_id,lft,rgt)"+
           "VALUES('Sadaļas','Admin::Action',4,1,1,12,13)")
    insert("INSERT INTO menu_items (name,menuable_type,menuable_id,menu_id,parent_id,lft,rgt)"+
           "VALUES('Lauki','Admin::Action',5,1,1,14,15)")
    insert("INSERT INTO menu_items (name,menuable_type,menuable_id,menu_id,parent_id,lft,rgt)"+
           "VALUES('Konfigurācija','Admin::Action',6,1,1,16,17)")
    insert("INSERT INTO menu_items (name,menuable_type,menuable_id,menu_id,parent_id,lft,rgt)"+
           "VALUES('Jauns lietotājs','Admin::Action',7,1,4,3,4)")
    insert("INSERT INTO menu_items (name,menuable_type,menuable_id,menu_id,parent_id,lft,rgt)"+
           "VALUES('Jauna loma','Admin::Action',8,1,5,7,8)")
    insert("INSERT INTO menu_items (name,menuable_type,menuable_id,menu_id,parent_id,lft,rgt)"+
           "VALUES('Draudzīgās adreses','Admin::Action',9,1,1,18,19)")
    if Lolita.config.translation
      insert("INSERT INTO menu_items (name,menuable_type,menuable_id,menu_id,parent_id,lft,rgt)"+
             "VALUES('Tulkojumi','Admin::Action',10,1,1,20,21)")
    end
  end

  def self.down
    drop_table :menu_items
  end
end
