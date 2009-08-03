class CreateWikiPages < ActiveRecord::Migration
  def self.up
    create_table :wiki_pages do |t|
       t.column :name, :string, :limit => 30
       t.column :content, :text
      t.timestamps
    end
  end

  def self.down
    drop_table :wiki_pages
  end
end
