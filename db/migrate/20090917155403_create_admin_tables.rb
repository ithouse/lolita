class CreateAdminTables < ActiveRecord::Migration
  def self.up
    create_table :admin_tables,:force=>true do |t|
      t.string :name
      t.string :human_name
    end
  end

  def self.down
    drop_table :admin_tables
  end
end
