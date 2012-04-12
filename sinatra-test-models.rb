class Post
  include Mongoid::Document
  field :title, type: String
  field :body, type: String
  field :is_public, type: Boolean
  field :price, type: BigDecimal
  field :published_at, type: DateTime, default: -> { Time.now }
  field :expire_date, type: Date
  include Lolita::Configuration

  lolita
end