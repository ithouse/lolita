require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Lolita::DBI::RecordSet do
  before(:each) do
    @dbi=Lolita::DBI::Base.new(TestClass1)
  end

  after(:each) do
    @recs||=[]
    @recs.each{|r| r.destroy}
  end
  
  it "should create record set" do
    set=Lolita::DBI::RecordSet.new(@dbi)
    set.records.should be_empty
  end

  it "should get records when any array metod or enumerable method is called on set" do
    create_recs
    set=Lolita::DBI::RecordSet.new(@dbi)
    set.is_loaded?.should be_false
    set.records.size.should == 0
    set.size.should == 2
    set.records.size.should == 2
  end
end

