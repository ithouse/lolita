class CreateFields < ActiveRecord::Migration
  def self.up
    create_table :admin_fields do |t|
      t.string  :name
      t.string  :human_name
      t.string  :table
    end
    add_index :admin_fields, [:table,:name]
  end

  def self.down
    drop_table :admin_fields
  end
end
