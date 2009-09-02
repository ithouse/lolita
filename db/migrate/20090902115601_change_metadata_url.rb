class ChangeMetadataUrl < ActiveRecord::Migration
  def self.up
    change_column :meta_datas,:url,:string
    add_index :meta_datas, :url
  end

  def self.down
    remove_index :meta_datas, :column=>:url
    change_column :meta_datas,:url,:text
  end
end