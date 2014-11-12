class Profile < ActiveRecord::Base
  include Lolita::Configuration
  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_and_belongs_to_many :preferences
  has_one :address
  lolita do
  end
end
