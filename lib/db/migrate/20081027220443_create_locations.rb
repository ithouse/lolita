class CreateLocations < ActiveRecord::Migration
  def self.up
    create_table :locations do |t|
      t.decimal :lat, :precision=>15, :scale=>10
      t.decimal :lng, :precision=>15, :scale=>10
      t.string  :mappable_type
      t.integer :mappable_id
      t.string  :name
      t.text    :info
      t.integer :width
      t.integer :height
    end
  end

  def self.down
    drop_table :locations
  end
end
