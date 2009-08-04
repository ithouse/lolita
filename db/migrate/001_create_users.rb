class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :admin_users, :force => true do |t|
      t.string :login                     
      t.string :email                    
      t.string :crypted_password,          :limit => 40
      t.string :salt,                      :limit => 40          
      t.string :remember_token
      t.datetime :remember_token_expires_at
      t.timestamp :reset_password_expires_at
      t.string    :type
      t.boolean   :deleted
    end
    add_index :admin_users, :login
    insert("INSERT INTO admin_users (login,email,crypted_password,salt,type) VALUES('atbalsts@ithouse.lv','atbalsts@ithouse.lv','152f9a74dc5ef5bf1d17b80b513f70b190e24199','f15c1dcd585628112cc4076f8dd31a877e342fce','Admin::SystemUser')")
 end

  def self.down
    drop_table :admin_users
  end
end
