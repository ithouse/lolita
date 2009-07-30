class UpdatePictureWithCompressionFlag < ActiveRecord::Migration
  def self.up
    add_column :pictures, :is_compressed, :boolean, :null=>false, :default=>0
  end

  def self.down
    remove_column :pictures, :is_compressed
  end
end
