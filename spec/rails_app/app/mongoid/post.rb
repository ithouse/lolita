class Post
  include Mongoid::Document
  include Lolita::Configuration
  field :title, :type => String
  field :body, :type => String
  field :is_public, :type => Boolean
  field :price, :type => BigDecimal
  references_many :comments,:class_name=>"Comment"
  referenced_in :profile
  validates_presence_of :title

  accepts_nested_attributes_for :comments, :reject_if => :all_blank

  lolita
end