class CreateMediaGoogleMaps < ActiveRecord::Migration
  def self.up
    create_table :media_google_maps do |t|
      t.integer :mappable_id
      t.string  :mappable_type
      t.float :lat
      t.float :lng
      t.text  :description
      t.timestamps
    end
  end

  def self.down
    drop_table :media_google_maps
  end
end
