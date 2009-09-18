class CreateFileTempMemory < ActiveRecord::Migration
  def self.up
    create_table :media_file_temp_memories,:id=>false do |t|
      t.integer :media_file_id
      t.string  :media
      t.integer :user_id
      t.integer :memory_id
    end
    add_index :media_file_temp_memories, :memory_id
    add_index :media_file_temp_memories,[:memory_id,:user_id,:media],:name=>"memory_user_media_index"
  end

  def self.down
    drop_table :media_file_temp_memories
  end
end
