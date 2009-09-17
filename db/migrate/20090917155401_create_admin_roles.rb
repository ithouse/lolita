class CreateAdminRoles < ActiveRecord::Migration
  def self.up
    create_table :roles_users, :id => false, :force => true  do |t|
      t.integer :user_id
      t.integer :role_id
    end
    create_table :admin_roles, :force => true do |t|
      t.string :name,               :limit => 40
      t.boolean :built_in
      t.string :authorizable_type,  :limit => 30
      t.integer :authorizable_id
    end
    add_index :roles_users, :user_id
    add_index :roles_users, :role_id
    add_index :roles_users, [:user_id, :role_id], :name => "user_role_index"

  end

  def self.down
    drop_table :admin_roles
    drop_table :roles_users
  end
end
