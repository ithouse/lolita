class CreateMetaDatas < ActiveRecord::Migration
  def self.up
    create_table :meta_datas do |t|
      t.string    :title
      t.string    :metaable_type
      t.integer   :metaable_id
      t.text      :url
      t.text      :tags
      t.text      :description
    end
    add_index :meta_datas, [:metaable_type,:metaable_id]
  end

  def self.down
    drop_table :meta_datas
  end
end
