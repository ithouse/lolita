class Post
  include Mongoid::Document
  include Lolita::Configuration
  field :title, :type => String
  field :body, :type => String
  references_many :comments,:class_name=>"Comment"
  referenced_in :profile
  lolita
end