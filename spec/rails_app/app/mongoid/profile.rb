class Profile
  include Mongoid::Document
  include Lolita::Configuration
  field :name, :type=>String
  field :age
  field :genere
  has_many :posts
  has_many :comments
  has_and_belongs_to_many :preferences
  embeds_one :address
  lolita do

  end
end