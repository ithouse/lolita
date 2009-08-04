ActionController::Routing::Routes.draw do |map|
  map.connect  'admin',  :controller=>'admin/configuration', :action=>'list', :path_prefix => '/:locale'
  map.connect  'system/login',   :controller=>'admin/user',  :action=>'login'
  map.connect  'system/logout',  :controller=>'admin/user ', :action=>'logout'
  map.connect  'system/login',   :controller=>'admin/user',  :action=>'login', :path_prefix => '/:locale'
  map.connect  'system/logout',  :controller=>'admin/user ', :action=>'logout', :path_prefix => '/:locale'
  map.connect ':controller/:action', :path_prefix => '/:locale'
  map.connect ':controller/:action/:id', :path_prefix => '/:locale'
  map.connect ':controller/:action/:id.:format', :path_prefix => '/:locale'
end
