class CreateAdminIPFilters < ActiveRecord::Migration
  def self.up
    
    create_table :admin_ip_filters do |t|
      t.string  :name
      t.decimal  :start_address
      t.decimal  :end_address
      t.boolean :active
      t.timestamps
    end
    add_index :admin_ip_filters, :start_address
    add_index :admin_ip_filters, :end_address
  end

  def self.down
    drop_table :admin_ip_filters
  end
end
