require "active_record"

ActiveRecord::Base.establish_connection(database: ":memory:", adapter: "sqlite3", timeout: 500)
ActiveRecord::Schema.define do
  create_table :addresses, force: true do |t|
    t.string :street
    t.string :city
    t.string :state
    t.string :post_code
    t.integer :person_id
  end

  create_table :categories, force: true do |t|
    t.string :name
  end

  create_table :posts, force: true do |t|
    t.string :title
    t.text :body
    t.boolean :is_public
    t.float :price
    t.datetime :published_at
    t.date :expire_date
    t.integer :category_id
  end

  create_table :tags, force: true do |t|
    t.string :name
  end

  create_table :posts_tags, force: true do |t|
    t.integer :post_id
    t.integer :tag_id
  end

  create_table :comments, force: true do |t|
    t.text :body
    t.integer :post_id
    t.integer :profile_id
  end

  create_table :preferences, force: true do |t|
    t.string :name
  end

  create_table :profiles, force: true do |t|
    t.string :name
    t.integer :age
    t.string :genere
    t.integer :address_id
  end

end
