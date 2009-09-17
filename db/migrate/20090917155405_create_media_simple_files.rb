class CreateMediaSimpleFiles < ActiveRecord::Migration
  def self.up
    create_table :media_simple_files do |t|
      t.string    :name, :null=>false
      t.string    :fileable_type
      t.integer   :fileable_id
      t.integer   :position
      t.string    :name_mime_type
      t.decimal   :name_filesize
      t.timestamps
    end
    add_index :media_simple_files, [:fileable_type,:fileable_id], :name => "simple_file_fileable_index"
  end

  def self.down
    drop_table :media_simple_files
  end
end
