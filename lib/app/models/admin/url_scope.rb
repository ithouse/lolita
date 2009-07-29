class Admin::UrlScope < Cms::Base
  set_table_name :admin_url_scopes
  validates_presence_of :name,:scope
end
