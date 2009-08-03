class CreateUrlScopes < ActiveRecord::Migration
  def self.up
    create_table :admin_url_scopes do |t|
      t.string :name
      t.string :scope
    end

    insert("INSERT INTO admin_url_scopes (name,scope) VALUES ('cms/text_page','raksts')")
    insert("INSERT INTO admin_url_scopes (name,scope) VALUES ('cms/news_list','zinas')")
    insert("INSERT INTO admin_url_scopes (name,scope) VALUES ('cms/news','zina')")
   # insert("INSERT INTO admin_url_scopes (name,scope) VALUES ('cms/text_page','raksts')")
    #insert("INSERT INTO admin_url_scopes (name,scope) VALUES ('cms/text_page','raksts')")

  end

  def self.down
    drop_table :admin_url_scopes
  end
end
