class Preference
  include Mongoid::Document
  include Lolita::Configuration
  field :name
  references_many :profiles, :stored_as=>:array, :inverse_of=>:preferences
end