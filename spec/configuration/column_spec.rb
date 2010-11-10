require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Lolita::Configuration::Column do

  
  it "should create new column with Hash attributes" do
    column=Lolita::Configuration::Column.new(:name=>"col1",:title=>"Col1",:type=>String)
    column.name.should == "col1"
  end

  it "should create new column with Proc as block given" do
    p=Proc.new{
      name "col1"
      title "Col one"
      type String
    }
    column=Lolita::Configuration::Column.new &p
    column.type.should == String
  end

  it "should create new column with block given" do
    column=Lolita::Configuration::Column.new do
      name "col1"
      title "Col one"
      type String
    end
    column.title.should == "Col one"
  end

  it "should raise error when no name is provided for column" do
    lambda{
      Lolita::Configuration::Column.new do
        title "Col one"
      end
    }.should raise_error(ArgumentError, "Column must have name.")
  end
end

