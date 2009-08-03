class SearchController < ApplicationController
  allow :public=>[:result]
  def result
    render :layout=>'public'
  end
end
