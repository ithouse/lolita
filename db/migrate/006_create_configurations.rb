class CreateConfigurations < ActiveRecord::Migration
  def self.up
    create_table :admin_configurations,:force=>true do |t|
      t.string  :name
      t.string  :title
      t.text    :value
    end
    insert("INSERT INTO admin_configurations (name,title,value) VALUES('dynamic_form_email','Formu e-pasts','bugs@ithouse.lv')")
    insert("INSERT INTO admin_configurations (name,title,value) VALUES('list_per_page','CMS sarakstu ieraksti lapā','20')")
    insert("INSERT INTO admin_configurations (name,title,value) VALUES('start_page','Sistēmas sākumlapa','admin/configuration')")
    insert("INSERT INTO admin_configurations (name,title,value) VALUES('system_part_url_3','Sistēmas daļa 3','wiki_page')")
    insert("INSERT INTO admin_configurations (name,title,value) VALUES('system_part_name_3','Sistēmas daļas nosaukums 3','Palīdzība')")
    insert("INSERT INTO admin_configurations (name,title,value) VALUES('system_part_url_2','Sistēmas daļa 2','admin/configuration')")
    insert("INSERT INTO admin_configurations (name,title,value) VALUES('system_part_name_2','Sistēmas daļas nosaukums 2','Iestatījumi')")
    insert("INSERT INTO admin_configurations (name,title,value) VALUES('system_part_url_1','Sistēmas daļa 1','cms/home')")
    insert("INSERT INTO admin_configurations (name,title,value) VALUES('system_part_name_1','Sistēmas daļas nosaukums 1','Saturs')")
    insert("INSERT INTO admin_configurations (name,title,value) VALUES('default_title','Mājas lapas noklusētais virsraksts','Lolita')")
    insert("INSERT INTO admin_configurations (name,title,value) VALUES('system_title','Sistēmas nosaukums','Lolita: satura vadības sistēma')")
    insert("INSERT INTO admin_configurations (name,title,value) VALUES('cms_name','Satura vadības sistēmas nosaukums','ITH Lolita')")
  end

  def self.down
    drop_table :admin_configurations
  end
end
