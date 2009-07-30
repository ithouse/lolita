class CreateVideoFiles < ActiveRecord::Migration
  def self.up
    create_table :video_files do |t|
      t.string    :name
      t.string    :video_type
      t.integer   :video_id
      t.string    :name_mime_type
      t.decimal   :name_filesize
      t.timestamps
    end
    add_index :video_files, [:video_type,:video_id]
  end

  def self.down
    drop_table :video_files
  end
end
