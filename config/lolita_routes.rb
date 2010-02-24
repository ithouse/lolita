ActionController::Routing::Routes.draw do |map|
  map.connect  'admin',  :controller=>'admin/user', :action=>'list'
  map.connect  'admin',  :controller=>'admin/user', :action=>'list', :path_prefix => '/:locale'
  map.connect  'system/login',   :controller=>'admin/user',  :action=>'login'
  map.connect  'system/logout',  :controller=>'admin/user', :action=>'logout'
  map.connect  'system/login',   :controller=>'admin/user',  :action=>'login', :path_prefix => '/:locale'
  map.connect  'system/logout',  :controller=>'admin/user', :action=>'logout', :path_prefix => '/:locale'

  map.resources :accesses, :controller=>"admin/access",:only=>[:index],
    :member=>{:list=>:any,:current_roles=>:get}
  map.resources :roles, :controller=>"admin/role",:except=>[:show],
    :member=>{
      :list=>:any
    } do |role|
    role.resources :users, :controller=>"admin/user", :only=>[:index]
    role.resources :accesses, :controller=>"admin/access", :only=>[:index],:member=>{:add=>:any,:remove=>:any,:change=>:any}
  end
  map.resources :users, :controller=>"admin/user",:except=>[:index,:show],
    :member=>{
      :current_roles=>:get,
      :list=>:any
    },
    :collection=>{
      :login=>:any,
      :logout=>:get,
      :edit_self=>:any,
      :forgot_password=>:any,
      :change_password=>:any
    } do |user|
      user.resources :roles, :controller=>"admin/role", :only=>:none,
        :member=>[:add,:remove]
    end
  map.connect ':controller/:action', :path_prefix => '/:locale'
  map.connect ':controller/:action.:format', :path_prefix => '/:locale'
  map.connect ':controller/:action/:id', :path_prefix => '/:locale'
  map.connect ':controller/:action/:id.:format', :path_prefix => '/:locale'

  map.connect ':controller/:action'
  map.connect ':controller/:action.:format'
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'

  map.simple_captcha '/simple_captcha/:action', :controller => 'simple_captcha'
end
