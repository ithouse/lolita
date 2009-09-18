class CreateAdvancedFilters < ActiveRecord::Migration
  def self.up
    create_table :advanced_filters do |t|
      t.string  :name
      t.string  :class_name
    end
  end

  def self.down
    drop_table :advanced_filters
  end
end
