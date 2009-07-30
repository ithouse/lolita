class CreateAdvancedFilterFields < ActiveRecord::Migration
  def self.up
    create_table :advanced_filter_fields do |t|
      t.string  :name
      t.boolean :visible
      t.boolean :active
      t.string  :sign
      t.integer :advanced_filter_id
      t.text    :values
    end
    add_index :advanced_filter_fields, :advanced_filter_id
  end

  def self.down
    drop_table :advanced_filter_fields
  end
end
