# To change this template, choose Tools | Templates
# and open the template in the editor.

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

class MyController < ApplicationController
  include Lolita::Controllers::InternalHelpers
end

describe MyController do
  before(:each) do
     @controller.request.env["lolita.mapping"]=Lolita.mappings[:post]
  end

  it "should get resource name" do
    @controller.resource_name.should == :post
  end

  it "should get resource class" do
    @controller.resource_class.should == Post
  end

  it "should build resource" do
    @controller.send(:build_resource)
    @controller.resource.class.should == Post
  end

  it "should set resource" do
    new_post=Post.new
    @controller.send(:resource=,new_post)
    @controller.resource.should == new_post
    @controller.send(:resource=,nil)
    @controller.resource.should be_nil
  end
end

