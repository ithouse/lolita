class UpdateVideoWithRatio < ActiveRecord::Migration
  def self.up
    add_column :video_files, :ratio, :float
  end

  def self.down
    remove_column :video_files, :ratio
  end
end
