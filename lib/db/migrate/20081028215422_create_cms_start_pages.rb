class CreateCmsStartPages < ActiveRecord::Migration
  def self.up
    create_table :cms_start_pages do |t|
      t.string  :place
      t.integer :menu_item_id
    end
  end

  def self.down
    drop_table :cms_start_pages
  end
end
