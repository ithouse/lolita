require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Lolita::Configuration::Tab do
  before(:each) do
    @dbi=Lolita::DBI::Base.new(Post)
  end

  it "should create tab" do
    Lolita::Configuration::Tab.new(@dbi,:content)
  end

  it "should allow to set title" do
    tab=Lolita::Configuration::Tab.new(@dbi,:content) do
      title "My tab"
    end
    tab.title.should == "My tab"
  end
  
  it "should have default title that is humanized type" do
    tab=Lolita::Configuration::Tab.new(@dbi,:content)
    tab.title.should=="Content"
  end
  
  it "should raise error when no fields are given for default type tab" do
    lambda{
      Lolita::Configuration::Tab.new(@dbi)
    }.should raise_error Lolita::NoFieldsGivenError
  end

  it "should create tab when attributes are given" do
    tab=Lolita::Configuration::Tab.new(@dbi,:fields=>[{:name=>"field one"}])
    tab.fields.size.should == 1
  end

  it "should create tab when block is given" do
    tab=Lolita::Configuration::Tab.new(@dbi) do
      field :name=>"field one"
    end
    tab.fields.size.should == 1
  end

  it "should allow add fieldset to tab" do
    tab=Lolita::Configuration::Tab.new(@dbi) do
      field_set("Person information") do
        field :name=>"field one"
      end
    end
    tab.field_sets.should have(1).item
  end

  it "should keep order for fields added in tab and in tab fieldsets" do
    tab=Lolita::Configuration::Tab.new(@dbi) do
      field :name=>"one"
      field_set("Fieldset") do
        field :name=>"two"
        field :name=>"three"
      end
      field :name=>"four"
      field_set("Fieldset 2") do
        field :name=>"five"
      end
      field :name=>"six"
    end
    tab.fields.collect{|f| f.name}.should == [:"one",:"two",:"three",:"four",:"five",:"six"]
  end

  it "should get fields from fieldset" do
     tab=Lolita::Configuration::Tab.new(@dbi) do
      field :name=>"one"
      field_set("Fieldset") do
        field :name=>"two"
        field :name=>"three"
      end
    end
    tab.field_sets.first.fields.size.should == 2
  end

  it "should add default fields for any tab when specified" do
    tab=Lolita::Configuration::Tab.new(@dbi,:images) do
      default_fields
    end
    tab.fields.size.should > 0
  end

  it "should add nested fields" do
    tab=Lolita::Configuration::Tab.new(@dbi) do
      default_fields
      nested_fields_for("Comment") do
        default_fields
      end
    end
    dbi2=Lolita::DBI::Base.new(Comment)
    
    tab.fields.size.should == @dbi.fields.size+dbi2.fields.size
  end

  it "should detect that field is nested" do
    tab=Lolita::Configuration::Tab.new(@dbi) do
      default_fields
      nested_fields_for("Comment") do
        default_fields
      end
    end
    tab.fields.last.nested?.should be_true
  end
  
  it "should return nested fields for specified class" do
    tab=Lolita::Configuration::Tab.new(@dbi) do
      default_fields
      nested_fields_for("Comment") do
        default_fields
      end
    end
    tab.nested_fields_of("Comment").size.should > 0
  end

end

