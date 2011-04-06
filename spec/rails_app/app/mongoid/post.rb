class Post
  include Mongoid::Document
  include Lolita::Configuration
  field :title, :type => String
  field :body, :type => String
  field :is_public, :type => Boolean
  references_many :comments,:class_name=>"Comment"
  referenced_in :profile
  validates_presence_of :title
  lolita
end