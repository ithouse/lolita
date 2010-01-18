class UsersAddRenewPasswordHashField < ActiveRecord::Migration
  def self.up
    add_column :admin_users, :renew_password_hash, :string, :limit=>40
    add_index :admin_users, :renew_password_hash
  end

  def self.down
    remove_index :admin_users, :renew_password_hash
    remove_column :admin_users, :renew_password_hash
  end
end
