require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Lolita::Configuration::Field do
  before(:each) do
    @dbi=Lolita::DBI::Base.new(Post)
    @dbi2=Lolita::DBI::Base.new(Comment)
  end

  it "should create new field" do
    Lolita::Configuration::Field.new(@dbi,:title)
  end

  it "should create field when block given" do
    field=Lolita::Configuration::Field.new(@dbi) do
      name :title
    end
    field.name.should == :title
  end

  it "should create field from Hash arguments" do
    field=Lolita::Configuration::Field.new(@dbi,:name=>:title)
    field.name.should == :title
  end
  
  it "should raise error when no name specified" do
    lambda{
      Lolita::Configuration::Field.new(@dbi)
    }.should raise_error Lolita::FieldNameError
  end

  it "should allow set field value" do
    field=Lolita::Configuration::Field.new(@dbi) do
      name :custom_field
      value "Field value"
    end
    field.value.should == "Field value"
  end

  it "should allow set field value as block" do
    field=Lolita::Configuration::Field.new(@dbi) do
      value do |field|
        field.name.to_s.upcase
      end
      name :custom_field
    end
    field.value.should == "CUSTOM_FIELD"
  end
  
  it "should raise error when class don't respond to field method when not value specified" do
#    Lolita::Configuration::Field.new(@dbi,:title,:value=>"Field value")
#    lambda{
#      Lolita::Configuration::Field.new(@dbi,:noname)
#    }.should raise_error Lolita::FieldNameError
  end
  
  it "should always set field title if not specified" do
    field=Lolita::Configuration::Field.new(@dbi,:title)
    field.title.size.should > 0
  end

  it "should raise error when field is nested in class that do not reference to field class" do
    lambda{
      field=Lolita::Configuration::Field.new(@dbi,:title,:nested_in=>Lolita::DBI::Base.new(Address))
    }.should raise_error Lolita::ReferenceError
  end

  it "should detect if field is nested in" do
    field=Lolita::Configuration::Field.new(@dbi2,:body,:nested_in=>@dbi)
    field.nested?.should be_true
  end

  it "should detect if field is nested in given class" do
    field=Lolita::Configuration::Field.new(@dbi2,:body,:nested_in=>@dbi)
    field.nested_in?(@dbi.klass).should be_true
  end

  it "should return field value" do
    post=Post.create!(:title=>"First post")
    field=Lolita::Configuration::Field.new(@dbi,:title,:record=>post)
    field.value.should==post.title
  end

  it "should detect type and create field with specified type" do
    require "rails_app/lib/lolita/configuration/field/my_custom_collection"
    field=Lolita::Configuration::Field.add(@dbi,:comments, :my_custom_collection)
    field.type.should == "my_custom_collection"
  end

  it "should detect field type when not specified" do
    field=Lolita::Configuration::Field.add(@dbi,:is_public)
    field.type.should == "boolean"
  end

  it "should change field type for association columns if custom type is given" do

  end

  it "should set field title when not specified" do
    field=Lolita::Configuration::Field.new(@dbi,:title)
    field.title.should == "Title"
  end

  it "should allow set field that is referenced in (belongs_to) any class" do
    field=Lolita::Configuration::Field.add(@dbi2,:post)
    field.type.should == "collection"
    field.association_type.should == :one
  end

  it "should allow set field that references to (has_many or has_one) any class" do
    field=Lolita::Configuration::Field.add(@dbi,:comments)
    field.type.should == "collection"
    field.association_type.should == :many
  end

end

