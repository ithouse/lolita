class CreateTables < ActiveRecord::Migration
  def self.up
    create_table :admin_tables,:force=>true do |t|
      t.string :name
      t.string :human_name
    end
    insert("INSERT INTO admin_tables (name,human_name) VALUES('admin/user','Lietotāji')")
    insert("INSERT INTO admin_tables (name,human_name) VALUES('admin/role','Lomas')")
    insert("INSERT INTO admin_tables (name,human_name) VALUES('admin/access','Pieejas')")
    insert("INSERT INTO admin_tables (name,human_name) VALUES('admin/url_scope','Draudzīgie nosaukumi')")
    insert("INSERT INTO admin_tables (name,human_name) VALUES('admin/configuration','Konfigurācija')")
    insert("INSERT INTO admin_tables (name,human_name) VALUES('admin/table','Sadaļas')")
    insert("INSERT INTO admin_tables (name,human_name) VALUES('admin/field','Lauki')")
    insert("INSERT INTO admin_tables (name,human_name) VALUES('admin/menu','Izvēlne')")
    insert("INSERT INTO admin_tables (name,human_name) VALUES('admin/menu_item','Izvēļņu ieraksti')")
  end

  def self.down
    drop_table :admin_tables
  end
end
