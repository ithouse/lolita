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
    insert("INSERT INTO admin_users (login,email,crypted_password,salt,type) VALUES('admin','admin@example.com','78437eec8760ac08ad9cab98b6dfc516c31be062','f15c1dcd585628112cc4076f8dd31a877e342fce','Admin::SystemUser')")
 end

  def self.down
    drop_table :admin_users
  end
end
