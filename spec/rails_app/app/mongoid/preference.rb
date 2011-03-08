class Preference
  include Mongoid::Document
  include Lolita::Configuration
  field :name
  references_and_referenced_in_many :profiles, :inverse_of=>:preferences
end