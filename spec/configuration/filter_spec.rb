require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Lolita::Configuration::Filter do

  before(:each) do
    @dbi=Lolita::DBI::Base.new(Post)
  end

  it "should create new filter with block" do
    Lolita::Configuration::Filter.new(@dbi) do

    end
  end

  it "should create new filter without block" do
    Lolita::Configuration::Filter.new(@dbi)
  end

  it "should give fields as arguments" do
    list=Lolita::Configuration::List.new(@dbi)
    list.filters :name, :is_public
    list.filters.fields.size.should == 2
  end
  
  it "should add default search field if none is given" do
    filter=Lolita::Configuration::Filter.new(@dbi)
    filter.fields.size.should == 1
    filter=Lolita::Configuration::Filter.new(@dbi){}
    filter.fields.size.should == 1
  end

  it "should add some fields" do
    filter=Lolita::Configuration::Filter.new(@dbi) do
      fields :name, :is_public, :not_public
    end
    filter.fields.size.should == 3
  end

  it "should add some field with block" do
    filter=Lolita::Configuration::Filter.new(@dbi) do
      field :name do
        type :integer
      end
    end
    filter.fields.first.type.should == "integer"
  end

  it "should add some fields with block" do
    filter=Lolita::Configuration::Filter.new(@dbi) do
      fields :name, :is_public do
        type :integer
      end
      field :created_at, :datetime
    end
    filter.fields.size.should == 3
    filter.fields[0].type.should == "integer"
    filter.fields[1].type.should == "integer"
    filter.fields[2].type.should == "datetime"
  end
end