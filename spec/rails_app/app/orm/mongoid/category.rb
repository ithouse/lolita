class Category
  include Mongoid::Document
  include Lolita::Configuration
  field :name, type: String
  has_many :posts

  lolita do
    list do
      list(:posts) do
        column :comments do
          list do
            column :body
          end
        end
      end
    end
  end
end
