class CreateAdminUsers < ActiveRecord::Migration
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
      t.references :preference
    end
    add_index :admin_users, :login
 end

  def self.down
    drop_table :admin_users
  end
end
