require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Lolita::Configuration::Tab do
  before(:each) do
    @dbi=Lolita::DBI::Base.new(TestClass1)
  end

  it "should create tab" do
    Lolita::Configuration::Tab.new(@dbi,:content)
  end

  it "should raise error when no fields are given for default type tab" do
    lambda{
      Lolita::Configuration::Tab.new(@dbi)
    }.should raise_error ArgumentError, "Fields must be specified for default tab."
  end

  it "should create tab when attributes are given" do
    tab=Lolita::Configuration::Tab.new(@dbi,:fields=>[{:name=>"field one"}])
    tab.fields.size.should == 1
  end

  it "should create tab when block is given" do
    tab=Lolita::Configuration::Tab.new(@dbi) do
      field :name=>"field one"
    end
    tab.fields.size.should == 1
  end

  it "should create "
end

