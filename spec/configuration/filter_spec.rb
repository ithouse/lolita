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
    list.filter :name, :is_public
    list.filter.fields.size.should == 2
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
      field :created_at, :time
    end
    filter.fields.size.should == 3
    filter.fields[0].type.should == "integer"
    filter.fields[1].type.should == "integer"
    filter.fields[2].type.should == "time"
  end

  it "should generate correct field_name" do
    filter=Lolita::Configuration::Filter.new(@dbi)
    filter.fields :name, :not_public
    filter.field_name(filter.fields.first).should == "f_name"
    filter.field_name(filter.fields.last).should == "f_not_public"
  end

  it "should return right options_for_select" do
    3.times{ Factory.create(:category)}
    filter=Lolita::Configuration::Filter.new(@dbi) do
      field :category
      field :some_type, :array, :options_for_select => %w(a b c)
    end
    options = filter.options_for_select(filter.fields.first)
    options.size.should == 3
    options.first.first.should be_an(String)
    options.first.last.should be_an(BSON::ObjectId)
    options = filter.options_for_select(filter.fields.last)
    options.size.should == 3
    options.should == %w(a b c)
  end

  it "should filter results for boolean" do

  end

  it "should filter results for belongs_to" do

  end
end