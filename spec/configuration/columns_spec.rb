require 'spec_helper'

describe Lolita::Configuration::Columns do

  let(:dbi){Lolita::DBI::Base.create(Post)}

  it "should create columns" do
    columns=Lolita::Configuration::Columns.new(dbi)
    columns.class.should == Lolita::Configuration::Columns
  end

  it "should respond to array methods" do
    columns=Lolita::Configuration::Columns.new(dbi)
    columns.size.should == 0
  end

  it "should generate columns from dbi class" do
    columns=Lolita::Configuration::Columns.new(dbi)
    columns.generate!
    columns.last.should_not be_nil
  end

  it "should make Lolita::Configuration::Column for each element " do
    columns=Lolita::Configuration::Columns.new(dbi)
    columns<<{:name=>"col1"}
    columns<<Lolita::Configuration::Column.new(dbi,:name=>"col2")
    columns.first.class.should == Lolita::Configuration::Column
  end

  it "should make Lolita::Configuration::Column from Symbol as name" do
    columns=Lolita::Configuration::Columns.new(dbi)
    columns<<:col1
    columns.first.class.should == Lolita::Configuration::Column
  end

  it "should make ::Column object with given block" do
    columns=Lolita::Configuration::Columns.new(dbi)
    columns<<(Proc.new{
        name "col1"
      })
    columns.first.name.should == :col1
    columns.column do 
      name :col2
    end
    columns.last.name.should == :col2
  end
end

