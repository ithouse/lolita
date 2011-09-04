require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Lolita::Configuration::Field do
  before(:each) do
    @dbi=Lolita::DBI::Base.create(Post)
    @dbi2=Lolita::DBI::Base.create(Comment)
  end

  let(:field_class){Lolita::Configuration::Field::Base}

  it "should create new field" do
    Lolita::Configuration::Field::Base.new(@dbi,:title,:string)
  end

  it "should create field when block given" do
    field=field_class.new(@dbi,:title,:string) do
  
    end
    field.name.should == :title
  end

  it "should raise error when no name specified" do
    lambda{
     field_class.new(@dbi,nil,nil)
    }.should raise_error Lolita::FieldNameError
  end

  it "should raise error when class don't respond to field method when not value specified" do
#    Lolita::Configuration::Field.new(@dbi,:title,:value=>"Field value")
#    lambda{
#      Lolita::Configuration::Field.new(@dbi,:noname)
#    }.should raise_error Lolita::FieldNameError
  end
  
  it "should always set field title if not specified" do
    field=field_class.new(@dbi,:title)
    field.title.size.should > 0
  end

  it "should raise error when field is nested in class that do not reference to field class" do
    lambda{
      field=field_class.new(@dbi,:title,:nested_in=>Lolita::DBI::Base.new(Address))
    }.should raise_error Lolita::ReferenceError
  end

  it "should detect if field is nested in" do
    field=field_class.new(@dbi2,:body,:nested_in=>@dbi)
    field.nested?.should be_true
  end

  it "should detect if field is nested in given class" do
    field=field_class.new(@dbi2,:body,:nested_in=>@dbi)
    field.nested_in?(@dbi.klass).should be_true
  end

  it "should detect type and create field with specified type" do
    require "rails_app/lib/lolita/configuration/field/my_custom_collection"
    field=Lolita::Configuration::Factory::Field.add(@dbi,:comments, :my_custom_collection)
    field.type.should == "my_custom_collection"
  end

  it "should fallback to string type if given type is not supported" do
    field=Lolita::Configuration::Factory::Field.add(@dbi,:is_public)
    field.type.should == "boolean"
  end

  it "should change field type for association columns if custom type is given" do
    pending
  end

  it "should set field title when not specified" do
    field=field_class.new(@dbi,:title)
    field.title.should == "Title"
  end

  it "should allow set field that is referenced in (belongs_to) any class" do
    field=Lolita::Configuration::Factory::Field.add(@dbi2,:post,:array)
    field.type.should == "array"
    field.association.macro.should == :one
  end

  it "should allow set field that references to (has_many or has_one) any class" do
    field=Lolita::Configuration::Factory::Field.add(@dbi,:comments,:array)
    field.type.should == "array"
    field.association.macro.should == :many
  end

end

