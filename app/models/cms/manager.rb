class Cms::Manager < Cms::Base
  self.abstract_class = true
  has_one :meta_data, :as => :metaable, :dependent => :destroy
  include Extensions::TinyMceExtensions
  class << self
    
  end
end
