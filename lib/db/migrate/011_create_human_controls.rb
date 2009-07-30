class CreateHumanControls < ActiveRecord::Migration
  def self.up
    create_table :human_controls do |t|
      t.string :text
      t.string :salt
      t.string :picture
      t.integer :picture_id
      t.timestamps
    end
  end

  def self.down
    drop_table :human_controls
  end
end
