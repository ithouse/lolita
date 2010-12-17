class Post
  include Mongoid::Document
  include Lolita::Configuration
  field :title
  field :body
  references_many :comments,:class_name=>"Comment"
  referenced_in :profile
  lolita
end