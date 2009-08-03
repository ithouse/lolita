class CreateFiles < ActiveRecord::Migration
  def self.up
    create_table :files do |t|
      t.string    :name, :null=>false
      t.string    :fileable_type
      t.integer   :fileable_id
      t.string    :name_mime_type
      t.integer   :name_filesize
      t.boolean   :is_public, :default=>1
      t.integer   :role_id
      t.integer   :user_id
      t.string    :caption
      t.string    :title
      t.integer   :position
      t.timestamps
    end
    add_index :files, [:fileable_type,:fileable_id]
  end

  def self.down
    drop_table :files
  end
end
