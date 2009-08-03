class CreateAccesses < ActiveRecord::Migration
  def self.up
    create_table :admin_accesses do |t|
      t.string :name
    end
     create_table :accesses_roles do |t|
      t.integer :role_id,    :null=>false
      t.integer :access_id, :null=>false
      t.boolean :allow_read
      t.boolean :allow_write
      t.boolean :allow_delete
      t.boolean :allow_update
    end
    add_index :admin_accesses, :name
    add_index :accesses_roles, [:role_id,:access_id]
    add_index :accesses_roles, :role_id
    add_index :accesses_roles, :access_id
  end

  def self.down
    drop_table :accesses_roles
    drop_table :admin_accesses
  end
end
