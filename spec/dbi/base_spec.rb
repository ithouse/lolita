require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Lolita::DBI::Base do
#  before(:each) do
#    @base = Base.new
#  end

  it "should raise error when not ORM class is given" do
    lambda{
      Lolita::DBI::Base.new(String)
    }.should raise_error Lolita::NotORMClassError
    lambda{
      Lolita::DBI::Base.new()
    }.should raise_error ArgumentError
  end

  it "should detect adapter" do
    dbi=Lolita::DBI::Base.new(TestClass1)
    dbi.klass.should == TestClass1
    Lolita::DBI::Base.adapters.should include(dbi.adapter)
  end

  it "should connect adapter" do
    dbi=Lolita::DBI::Base.new(TestClass1)
    lambda{
      dbi.fields
    }.should_not raise_error
  end

  it "should display all adapter available" do
    Lolita::DBI::Base.adapters.size.should > 0
  end
end

