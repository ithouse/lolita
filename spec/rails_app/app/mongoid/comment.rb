class Comment
  include Mongoid::Document
  field :body
  referenced_in :post
  referenced_in :profile
end