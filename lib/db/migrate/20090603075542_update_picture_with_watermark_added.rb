class UpdatePictureWithWatermarkAdded < ActiveRecord::Migration
  def self.up
    require "picture"
    add_column :pictures, :watermark_added, :boolean
    Picture.update_all("watermark_added=1")
  end

  def self.down
    remove_column :pictures, :watermark_added
  end
end
