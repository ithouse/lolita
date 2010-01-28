class UpdateAdminUserIndexes < ActiveRecord::Migration
  def self.up
    add_index :admin_users, :type
  end

  def self.down
    remove_index :admin_users, :type
  end
end
