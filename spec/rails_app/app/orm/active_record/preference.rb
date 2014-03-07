class Preference < ActiveRecord::Base
  include Lolita::Configuration
  has_and_belongs_to_many :profiles
end
