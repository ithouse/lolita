require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module Lolita
  module Configuration
    module Tab
      class Images < Lolita::Configuration::Tab::Base
      end
      class Translation < Lolita::Configuration::Tab::Base
      end
    end
  end
end

describe Lolita::Configuration::Tabs do
  before(:each) do
    @dbi=Lolita::DBI::Base.create(Post)
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
      tab(:content)
    end
    tabs.size.should == 1
  end

  it "should create tabs when specified as arguments" do
    tabs=Lolita::Configuration::Tabs.new(@dbi,:tabs=>[Lolita::Configuration::Tab::Base.new(@dbi,:content)])
    tabs.size.should == 1
  end

  it "should create default tabs" do
    tabs=Lolita::Configuration::Tabs.new(@dbi) do
      default :content,:images
    end
    tabs.size.should > 0
  end

  it "should exclude all default tabs" do
    tabs=Lolita::Configuration::Tabs.new(@dbi) do
      exclude :all
    end
    tabs.size.should == 0
    tabs.excluded.size.should > 0
  end

  it "should exclude specific tabs" do
    tabs=Lolita::Configuration::Tabs.new(@dbi)
    tabs.exclude :images
    tabs.excluded.size.should == 1
  end

  it "should add tabs" do
    tabs=Lolita::Configuration::Tabs.new(@dbi,:exclude=>:all)
    tabs<<:images
    tabs<<:content
    tabs.size.should == 2
  end

  it "should raise error when two same type tabs are added" do
    lambda{
      tabs=Lolita::Configuration::Tabs.new(@dbi) do
        tab :content
        tab :content
      end
    }.should raise_error Lolita::SameTabTypeError
  end

  it "should create real tabs when not tab is provided" do
    tabs=Lolita::Configuration::Tabs.new(@dbi,:default=>:content)
    tabs<<:images
    tabs<<:translation
    tabs[tabs.size-2].class.should == Lolita::Configuration::Tab::Images
    tabs[tabs.size-1].class.should == Lolita::Configuration::Tab::Translation
  end

  it "should return all tab names" do
    tabs=Lolita::Configuration::Tabs.new(@dbi) do
      tab :content
    end
    tabs.names.size.should > 0
  end

  context "tab finding" do
    it "should find by type" do
      tabs=Lolita::Configuration::Tabs.new(@dbi) do
        tab :default do
          field :name, :string
        end
        tab :content
      end
      tabs.by_type(:content).should_not be_nil
    end

  end
end

