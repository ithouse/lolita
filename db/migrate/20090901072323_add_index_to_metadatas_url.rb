class AddIndexToMetadatasUrl < ActiveRecord::Migration
  def self.up
    #add_index :meta_datas, :"url (255)"
  end

  def self.down
    #remove_index :meta_datas, :column=>[:url]
  end
end