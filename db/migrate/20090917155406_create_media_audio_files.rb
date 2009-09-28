class CreateMediaAudioFiles < ActiveRecord::Migration
  def self.up
    create_table :media_audio_files do |t|
      t.string    :name
      t.string    :audio_type
      t.integer   :audio_id
      t.string    :name_mime_type
      t.decimal   :name_filesize
      t.timestamps
    end
    add_index :media_audio_files, [:audio_type,:audio_id]
  end

  def self.down
    drop_table :media_audio_files
  end
end
