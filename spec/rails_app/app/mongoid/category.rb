class Category
  include Mongoid::Document
  include Lolita::Configuration
  field :name, type: String
  has_many :posts
end