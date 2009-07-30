class UpdatePicturesWithMainpictureIndex < ActiveRecord::Migration
  def self.up
    add_index :pictures, :main_image
    add_index :pictures, :position
  end

  def self.down
    remove_index :pictures, :column=>:main_image
    remove_index :pictures, :column=>:position
  end
end
