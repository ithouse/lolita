class Comment
  include Mongoid::Document
  field :body
  belongs_to :post
  belongs_to :profile
end