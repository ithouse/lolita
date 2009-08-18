ActionController::Routing::Routes.draw do |map|
  map.connect  'admin',  :controller=>'admin/configuration', :action=>'list'
  map.connect  'system/login',   :controller=>'admin/user',  :action=>'login'
  map.connect  'system/logout',  :controller=>'admin/user ', :action=>'logout'
  
  map.connect ':controller/:action'
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
