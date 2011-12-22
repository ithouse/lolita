require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Lolita::Configuration::Base do

  it "should define configuration without block" do
    Post.lolita.should_not be_nil
  end

  it "should define configuration with block" do
    Profile.lolita.should_not be_nil
  end

  it "should not initialize instance methods for configuration without calling them" do
    Profile.lolita.list.to_s.should match(/Lolita::LazyLoader/)
    Post.lolita.list.to_s.should match(/Lolita::LazyLoader/)
  end

  it "should return real object when calling it" do
    Post.class_eval do
      lolita do
        list
      end
    end
    Post.lolita.list.class.to_s.should == "Lolita::Configuration::List"
  end

  it "should return tabs" do
    base_config = Lolita::Configuration::Base.new(Post)
    base_config.tabs.class.should == Lolita::Configuration::Tabs
  end

  it "should allow add tabs" do
    Post.class_eval do
      lolita do
        tab(:content)
      end
    end
    
    Post.lolita.tabs.size.should == 1
  end

end

