Rails.application.class.routes.draw do
  devise_for :admins, :path_prefix=>"lolita", :class_name=>"Lolita::Admin"
  match "/lolita", :to=>"lolita/home#index", :as=>"lolita_root"
end
