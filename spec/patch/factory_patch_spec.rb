require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Lolita::FactoryPatch do
  it "should build Admin::User object" do
    Factory.build("admin/user").class.should == Admin::User
  end
end

