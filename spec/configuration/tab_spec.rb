require 'spec_helper'

# temp class for extending tabs
class Lolita::Configuration::Tab::My < Lolita::Configuration::Tab::Base
  def initialize(dbi,type=nil,*args,&block)
    type = :my
    super
  end
end


describe Lolita::Configuration::Tab do

  before(:each) do
    @dbi=Lolita::DBI::Base.create(Post)
  end

  let(:tab_class){Lolita::Configuration::Tab::Base}

  def default_tab &block
    Lolita::Configuration::Tab::Base.new(@dbi,:default,&block)
  end

  describe "create extended tabs" do

    context "tab class is child class of ::Tab class " do
      it "should create new" do
        Lolita::Configuration::Tab::My.new(@dbi).type.should == :my
      end

      it "should create new with block" do
        Lolita::Configuration::Tab::My.new(@dbi) do 
          title "My New tab"
        end.title.should == "My New tab"
      end
    end
  end

  it "should create tab" do
    tab_class.new(@dbi,:content)
  end

  it "should allow to set title" do
    tab=tab_class.new(@dbi,:content) do
      title "My tab"
    end
    tab.title.should == "My tab"
  end
  
  it "should have default title that is humanized type" do
    tab=tab_class.new(@dbi,:content)
    tab.title.should=="Content"
  end
  
  it "should raise error when no fields are given for default type tab" do
    lambda{
      Lolita::Configuration::Factory::Tab.add(@dbi,:default)
    }.should raise_error Lolita::NoFieldsGivenError
  end

  it "should create tab when attributes are given" do
    tab=tab_class.new(@dbi,:default,:fields=>[{:name=>"field one"}])
    tab.fields.size.should == 1
  end

  it "should create tab when block is given" do
    tab=default_tab do
      field :name=>"field one"
    end
    tab.fields.size.should == 1
  end

  it "should allow add fieldset to tab" do
    tab=default_tab do
      field_set("Person information") do
        field :name=>"field one"
      end
    end
    tab.field_sets.should have(1).item
  end

  it "should keep order for fields added in tab and in tab fieldsets" do
    tab=default_tab do
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
    tab.fields.collect{|f| f.name }.should == [:"one",:"two",:"three",:"four",:"five",:"six"]
  end

  it "should get fields from fieldset" do
     tab=default_tab do
      field :name=>"one"
      field_set("Fieldset") do
        field :name=>"two"
        field :name=>"three"
      end
    end
    tab.field_sets.first.fields.size.should == 2
  end

  it "should add default fields for any tab when specified" do
    tab=tab_class.new(@dbi,:images) do
      default_fields
    end
    tab.fields.size.should > 0
  end

  describe "nested field operations" do 

    it "should add nested fields" do
      tab=default_tab do
        default_fields
        nested_fields_for(:comments) do
          default_fields
        end
      end
      dbi2=Lolita::DBI::Base.new(Comment)
      tab.fields.size.should == @dbi.fields.reject{|f| f.technical?}.size+dbi2.fields.reject{|f| f.technical?}.size
    end

    it "should detect that field is nested" do
      tab=default_tab do
        default_fields
        nested_fields_for(:comments) do
          default_fields
        end
      end
      tab.fields.last.nested?.should be_true
    end
  
    it "should return nested fields for specified class" do
      tab=default_tab do
        default_fields
        nested_fields_for(:comments) do
          default_fields
        end
      end
      tab.nested_fields_of(:comments).size.should > 0
    end

    it "should have nested forms" do
      tab = default_tab do
        default_fields
        nested_fields_for(:comments) do
          default_fields
        end
      end
      tab.nested_forms.should have(1).item
      tab.nested_forms[0].fields.size.should > 0
    end 

    it "should return nested field sets" do
      tab = default_tab do
        field :name => "one"
        nested_fields_for(:comments) do
          default_fields
        end
        field :name => "two"
        field :name => "last"
      end

      tab.fields_in_groups.size.should == 3
      tab.fields_in_groups[1].first.dbi == Comment
    end

  end

  it "should return field with given name" do
    tab=default_tab do
      default_fields
    end
    tab.fields.by_name(:title).name.should == :title
  end

end

