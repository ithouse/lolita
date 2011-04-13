class Address
  include Mongoid::Document
  field :street
  field :city
  field :state
  field :post_code
  embedded_in :person
end