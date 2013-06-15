require 'spec_helper'

describe Lolita::RestController do
  render_views

  before(:each) do
    @controller.request.env["lolita.mapping"]=Lolita.mappings[:post]
  end

  it "should create new nested resources together with base resource"
#  do
#    p = {:title=>"Post 1"}
#    p[:comments_attributes] = [{:body=>"Comment 1"}, {:body=>"Comment 2"}]
#    post :create, :post=>p
#    Post.last.title.should == "Post 1"
#    puts Comment.all.to_a.inspect
#    Post.first.comments.length.should == 2
#    Post.first.comments.last.body.should == "Comment 2"
#  end

  it "should create new nested resources for existing base resource"

  it "should add new nested resources for existing base resource with existing nested resourcer"

  it "should remove nested resources from base resource"

  it "should modify nested resources for given base resource"


end



