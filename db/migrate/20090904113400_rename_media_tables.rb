class RenameMediaTables < ActiveRecord::Migration
  def self.up
    rename_table :image_files, :media_image_files
    rename_table :audio_files, :media_audio_files
    rename_table :video_files, :media_video_files
    rename_table :files, :media_simple_files
  end

  def self.down
    rename_table :media_image_files,:image_files
    rename_table :media_audio_files,:audio_files
    rename_table :media_video_files,:video_files
    rename_table :media_simple_files,:files
  end
end
