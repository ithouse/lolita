class CreateAdminPortals < ActiveRecord::Migration
  def self.up
    create_table :admin_portals do |t|
      t.string  :domain
      t.boolean :root
    end
  end

  def self.down
    drop_table :admin_portals
  end
end
