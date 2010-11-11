require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Lolita::Configuration::Tabs do
  before(:each) do
    @dbi=Lolita::DBI::Base.new(TestClass1)
  end

  it "should create tabs when Array is given" do
    tabs=Lolita::Configuration::Tabs.new(@dbi)
    tabs.size.should == 0
  end

  it "should create tabs when block is given" do
    tabs=Lolita::Configuration::Tabs.new(@dbi) {}
    tabs.size.should == 0
  end

  it "should create tabs when specifid in block" do
    tabs=Lolita::Configuration::Tabs.new(@dbi) do
      tab 
    end
    tabs.size.should == 1
  end

  it "should create tabs when specified as arguments" do
    tabs=Lolita::Configuration::Tabs.new(@dbi,[:image,Tab.new(:content)])
    tabs.size.should == 2
  end

  it "should create default tabs" do
    tabs=Lolita::Configuration::Tabs.new(@dbi) do
      default :content,:images
    end
    tabs.size.should > 0
  end

  it "should exclude all default tabs" do
    tabs=Lolita::Configuation::Tabs.new(@dbi) do
      exclude
    end
    tabs.size.should == 0
    tabs.excluded.size.should > 0
  end

  it "should exclude specific tabs" do
    tabs=Lolita::Configuration::Tabs.new(@dbi)
    tabs.exclude :images
    tabs.ecluded.size.should == 1
  end

  it "should add tabs" do
    tabs=Lolita::Configuration::Tabs.new(@dbi,:exclude=>:all)
    tabs.add(:images)
    tabs<<:content
    tabs.size.should == 2
  end

  it "should raise error when two same type tabs are added" do
    lambda{
      tabs=Lolita::Configuration::Tabs.new(@dbi) do
        tab :content
        tab :content
      end
    }.should raise_error ArgumentError, "Two tabs of same type (content) are detected."
  end

  it "should create real tabs when not tab is provided" do
    tabs=Lolita::Configuration::Tabs.new(@dbi,:default=>:content)
    tabs.add(:images)
    tabs<<:translation
    tabs[tabs.size-2].class.should == Lolita::Configuration::Tab
    tabs[tabs.size-1].class.should == Lolita::Configuration::Tab
  end

  it "should return all tab names" do
    tabs=Lolita::Configuration::Tabs.new(@dbi)
    tabs.names.size.should > 0
  end

end

