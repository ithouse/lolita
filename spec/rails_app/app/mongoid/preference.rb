class Preference
  include Mongoid::Document
  include Lolita::Configuration
  field :name
  has_and_belongs_to_many :profiles
end