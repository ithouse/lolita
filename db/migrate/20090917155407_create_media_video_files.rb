class CreateMediaVideoFiles < ActiveRecord::Migration
  def self.up
    create_table :media_video_files do |t|
      t.string    :name
      t.string    :video_type
      t.integer   :video_id
      t.string    :name_mime_type
      t.decimal   :name_filesize
      t.float     :ratio
      t.timestamps
    end
    add_index :media_video_files, [:video_type,:video_id]
  end

  def self.down
    drop_table :media_video_files
  end
end
