require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Lolita::Configuration::Base do
#    before(:each) do
#      @base = Lolita::Configuration::Base.new
#    end

  it "should define configuration without block" do
    TestClass1.lolita.should_not be_nil
  end

  it "should define configuration with block" do
    TestClass2.lolita.should_not be_nil
  end

  it "should not initialize instance methods for configuration without calling them" do
    TestClass2.lolita.list.to_s.should match(/Lolita::LazyLoader/)
    TestClass1.lolita.list.to_s.should match(/Lolita::LazyLoader/)
  end

  it "should return real object when calling it" do
    define_config do
      list
    end
    TestClass1.lolita.list.class.to_s.should == "Lolita::Configuration::List"
  end

  it "should return tabs" do
    define_config
    TestClass1.lolita.tabs.class.should == Lolita::Configuration::Tabs
  end

  it "should allow add tabs" do
    define_config do
      tab
    end
    TestClass1.lolita.tabs.size.should == 1
  end
  
  def define_config &block
    TestClass1.lolita=Lolita::Configuration::Base.new(TestClass1,&block)
  end
end

