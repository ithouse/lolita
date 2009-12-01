require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::Menu do
  before(:each) do
    @menu = Factory(:"admin/menu")
  end

  it "should create blank menu" do
    @menu.class.should == Admin::Menu
  end
end

