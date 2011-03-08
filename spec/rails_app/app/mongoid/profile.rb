class Profile
  include Mongoid::Document
  include Lolita::Configuration
  field :name, :type=>String
  field :age
  field :genere
  references_many :posts
  references_many :comments
  references_and_referenced_in_many :preferences, :inverse_of=>:profiles
  embeds_one :address
  lolita do

  end
end