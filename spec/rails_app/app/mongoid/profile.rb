class Profile
  include Mongoid::Document
  include Lolita::Configuration
  field :name
  field :age
  field :genere
  references_many :posts
  references_many :comments
  references_many :preferences, :stored_as=>:array, :inverse_of=>:profiles
  embeds_one :address
  lolita do

  end
end