class Post
  include Mongoid::Document
  include Lolita::Configuration
  field :title, :type => String
  field :body, :type => String
  field :is_public, :type => Boolean
  field :price, :type => BigDecimal
  field :published_at, type: Time, default: -> { Time.now }
  field :expire_date, type: Date
  references_many :comments,:class_name=>"Comment"
  referenced_in :profile
  validates_presence_of :title
  lolita
end