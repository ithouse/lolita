class Post < ActiveRecord::Base
  include Lolita::Configuration
  belongs_to :category
  has_and_belongs_to_many :tags
  has_many :comments, dependent: :destroy
  belongs_to :profile
  validates :title, presence: true
  default_scope -> { order("title") }
  accepts_nested_attributes_for :comments, reject_if: :all_blank

  lolita do
    list do
      column :comments do
        list do
          column :body
        end
      end
    end
  end

  def self.custom_search query, request = nil, dbi = nil
    self.where("expire_date > ?", Date.today)
  end
end
