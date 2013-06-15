require 'spec_helper'

describe "Default Lolita routes" do

  it "should have routes for posts" do
    # ActionController::Routing::Routes.routes.each do |r|
    #   puts r
    # end
    # ActionController::Routing::Routes.named_routes.routes.each do |name, route|
    #   puts "%20s: %s" % [name, route]
    # end
    {:get=>'/lolita/posts'}.should be_routable
  end
end

