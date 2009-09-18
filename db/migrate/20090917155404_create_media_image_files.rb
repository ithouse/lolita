class CreateMediaImageFiles < ActiveRecord::Migration
  def self.up
    create_table   :media_image_files do |t|
      t.string      :name
      t.string      :pictureable_type
      t.integer     :pictureable_id
      t.boolean     :main_image
      t.string      :title
      t.string      :alt
      t.string      :caption
      t.integer     :position
      t.string      :name_mime_type
      t.decimal     :name_filesize
      t.boolean     :has_watermark
      t.timestamps
    end
    add_index :media_image_files, :main_image
    add_index :media_image_files, :position
    add_index :media_image_files, [:pictureable_type,:pictureable_id]
  end

  def self.down
    drop_table :media_image_files
  end
end
