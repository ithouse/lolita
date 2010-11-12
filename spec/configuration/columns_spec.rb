require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Lolita::Configuration::Columns do

  before(:each) do
    @dbi=Lolita::DBI::Base.new(TestClass1)
    @list=Lolita::Configuration::List.new(@dbi)
  end

  it "should create columns" do
    columns=Lolita::Configuration::Columns.new(@list)
    columns.class.should == Lolita::Configuration::Columns
  end

  it "should respond to array methods" do
    columns=Lolita::Configuration::Columns.new(@list)
    columns.size.should == 0
  end

  it "should generate columns from dbi class" do
    columns=Lolita::Configuration::Columns.new(@list)
    columns.generate!
    columns.last.name.should == "field_one"
  end

  it "should make Lolita::Configuration::Column for each element " do
    columns=Lolita::Configuration::Columns.new(@list)
    columns<<{:name=>"col1"}
    columns<<Lolita::Configuration::Column.new(:name=>"col2")
    columns.first.class.should == Lolita::Configuration::Column
  end

  it "should make Lolita::Configuration::Column from Symbol as name" do
    columns=Lolita::Configuration::Columns.new(@list)
    columns<<:col1
    columns.first.class.should == Lolita::Configuration::Column
    columns.add(:col2).add(:col3)
    columns.last.class.should == Lolita::Configuration::Column
    columns.size.should == 3
  end

  it "should make ::Column object with given block" do
    columns=Lolita::Configuration::Columns.new(@list)
    columns<<(Proc.new{
        name "col1"
      })
    columns.first.name.should == "col1"
    columns.add do
      name "col2"
    end
    columns.last.name.should == "col2"
  end
end

