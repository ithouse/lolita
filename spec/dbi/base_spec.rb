require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Lolita::DBI::Base do
#  before(:each) do
#    @base = Base.new
#  end

  it "should detect adapter" do
    dbi=Lolita::DBI::Base.new(TestClass1)
    dbi.klass.should == TestClass1
    Lolita::DBI::Base.adapters.should include(dbi.adapter)
  end

  it "should connect adapter" do
    dbi=Lolita::DBI::Base.new(TestClass1)
    lambda{
      dbi.fields.should_not raise_error
    }
  end
end

