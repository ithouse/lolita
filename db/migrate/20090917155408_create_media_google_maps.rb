class CreateMediaGoogleMaps < ActiveRecord::Migration
  def self.up
    create_table :media_google_maps do |t|
      t.integer :mappable_id
      t.string  :mappable_type
      t.decimal :lat, :precision => 15, :scale => 10
      t.decimal :lng, :precision => 15, :scale => 10
      t.integer :zoom, :null => true
      t.text  :description
      t.timestamps
    end
  end

  def self.down
    drop_table :media_google_maps
  end
end
