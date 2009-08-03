class Cms::StartPageController < ApplicationController
  allow :public=>[:show,:search]
  access_control :include=>[:show,:update,:open], :redirect_to=>{:action=>"update"}
  menu_actions :public=>{:search=>:"actions.search",:show=>"Start page"}

 
  def search
    
  end
  
  def show
    
  end


end
