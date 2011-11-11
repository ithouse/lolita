class Post
  include Mongoid::Document
  include Lolita::Configuration
  field :title, type: String
  field :body, type: String
  field :is_public, type: Boolean
  field :price, type: BigDecimal
  field :published_at, type: DateTime, default: -> { Time.now }
  field :expire_date, type: Date
  belongs_to :category
  has_and_belongs_to_many :tags
  has_many :comments
  belongs_to :profile
  validates_presence_of :title
  default_scope order_by([:title, :asc])
  accepts_nested_attributes_for :comments, :reject_if => :all_blank

  lolita

  def self.custom_search query,request=nil,dbi=nil
    self.where(:expire_date.gt => Date.today)
  end
end