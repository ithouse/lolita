class UpdatePictureWithSource < ActiveRecord::Migration
  def self.up
    add_column :pictures, :source_id, :integer
  end

  def self.down
    remove_column :pictures, :source_id
  end
end
