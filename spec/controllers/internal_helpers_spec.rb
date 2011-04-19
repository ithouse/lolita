# To change this template, choose Tools | Templates
# and open the template in the editor.

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

class MyController < ApplicationController
  include Lolita::Controllers::InternalHelpers
  include Lolita::Hooks
  add_hook :before_build_resource,:after_build_resource
  add_hook :before_index
  before_index :modify

  def index
    @@temp=1
    self.run_before_index
  end

  private

  def modify
    @@temp=3
  end
end

describe MyController do
  before(:each) do
     @controller.request.env["lolita.mapping"]=Lolita.mappings[:post]
  end

  it "should call hook in #index" do
    @controller.index
    @controller.class.class_variable_get(:"@@temp").should == 3
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

  it "should convert rails date_select and datetime_select values" do
    resource=Post.new
    sample_date = Date.civil(2011,1,1)
    attributes={:published_at => {}}
    @controller.send(:resource_with_attributes,resource,attributes)
  end

  it "should fix rails date attributes" do
    params = {"date_till(1i)"=>"2011", "date_till(2i)"=>"4", "date_till(3i)"=>"19", "description"=>"", "created_at(1i)"=>"2011", "created_at(2i)"=>"4", "created_at(3i)"=>"19", "created_at(4i)"=>"16", "created_at(5i)"=>"14"}
    attributes = @controller.send(:fix_attributes,params)
    attributes['date_till'].should == Date.new(2011,4,19)
  end

  it "should fix rails date_time attributes" do
    params = {"created_at(1i)"=>"2011", "created_at(2i)"=>"4", "created_at(3i)"=>"19", "created_at(4i)"=>"16", "created_at(5i)"=>"14"}
    attributes = @controller.send(:fix_attributes,params)
    attributes['created_at'].should == DateTime.new(2011,4,19,16,14)
  end

end

