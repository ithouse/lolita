class CreateUrls < ActiveRecord::Migration
  def self.up
    create_table :urls do |t|
      t.string  :name
      t.string  :addressable_type
      t.string  :addressable_id
    end
    add_index :urls, [:addressable_type,:addressable_id], :name=>"address_type_and_id"
  end

  def self.down
    drop_table :urls
  end
end