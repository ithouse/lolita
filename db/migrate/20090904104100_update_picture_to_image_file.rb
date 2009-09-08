class UpdatePictureToImageFile < ActiveRecord::Migration
  def self.up
    begin
      remove_column :pictures, :source_id
      remove_column :pictures, :watermark_added
      remove_column :pictures, :is_compressed
    rescue #May cause removed migrations
    end
    rename_table :pictures, :image_files
    rename_column :image_files, :picture, :name
  end

  def self.down
    rename_table :image_files, :pictures
    add_column :pictures, :is_compressed, :boolean, :null=>false, :default=>0
    add_column :pictures, :watermark_added
    add_column :pictures, :source_id, :integer
  end
end
