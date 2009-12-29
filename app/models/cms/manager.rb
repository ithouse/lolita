# Abstract class that add metadata reflection and include TinyMCE workaround methods.
# Every class that should use metadata should extend this class.
# Subclass of #Cms::Base
class Cms::Manager < Cms::Base
  self.abstract_class = true
  has_one :meta_data, :as => :metaable, :dependent => :destroy
  include Extensions::TinyMceExtensions
end
