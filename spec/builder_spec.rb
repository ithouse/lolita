require File.expand_path(File.dirname(__FILE__) + '/simple_spec_helper')

class SimpleObject 
  include Lolita::Builder
end

describe Lolita::Builder::Custom do
  let(:object){SimpleObject.new}
  let(:builder){Lolita::Builder::Custom.new(object,{})}
  let(:klass){Lolita::Builder::Custom}

  it "should create new Custom builder" do
    builder = Lolita::Builder::Custom.new(object,{})
  end

  it "should set name and state" do
    builder = Lolita::Builder::Custom.new(object,{:name => "name", :state=>"state"})
    builder.instance_variable_get(:"@name").should == "name"
    builder.instance_variable_get(:"@state").should == "state"
  end

  it "should set default attributes" do
    builder = Lolita::Builder::Custom.new(object,{:name => "name"})
    builder.instance_variable_get(:"@state").should == :display
  end

  describe "build attributes" do
    it "should set through #with" do
      builder.with("name","state").build_attributes.should == {:name => "name", :state => "state"}
      builder.with({:name=>"name",:state=>"state"}).build_attributes.should == {:name => "name", :state=>"state"}
      builder.with("name",:state=>"state").build_attributes.should == {:name=>"name",:state=>"state"}
    end
  end

  it "should return default state when no build attributes given" do
    builder.state.should == :display
  end

  it "should return build attributes state when given" do
    builder.with(:state=>"state").state.should == :"state"
  end

  it "should return default name when no build name given" do
    builder.name.should == :"/simple_object"
  end

  it "should return build name when given" do
    builder.with(:name => "name").name.should == :"/simple_object/name"
    builder.with(:name => "/name").name.should == :"/name"
  end

  describe "#build" do
    it "should return array with name,state and options" do
      builder.build.should == [:"/simple_object",:"display",{}]
      builder.with({:display_value => 1}).build.should == [:"/simple_object",:display,{:display_value=>1}]
    end
  end

  describe "conditions" do
    it "should use given over default when there's no conditions" do
      builder = klass.new(object,:name => "/custom", :state => "special")
      builder.build.should == [:"/custom",:"special",{}]
    end

    it "should use given over default when conditions met" do
      builder = klass.new(object, :name => "/custom", :state=>"special", :unless=>{:state=>"display"})
      builder.build.should == [:"/simple_object",:"display",{}]
      builder.class_eval do
        def default_state
          :other
        end
      end
      builder.build.should == [:"/custom",:special,{}]
    end

    it "should use given over build given when conditions met" do
      builder = klass.new(object,:name => "/custom", :"state" => "special", :if=>{:state=>"default"})
      builder.with(:state => "other").build.should == [:"/simple_object",:other,{}]
      builder.with(:state => :default).build.should == [:"/custom",:special,{}]
    end
  end
end

describe Lolita::Builder do

  let(:object){SimpleObject.new}

  describe "#build" do

    describe "default path" do

      it "should be /:class_name/display" do
        info=object.build
        info.first.should == :"/simple_object"
        info[1].should == :display
      end

      it "should use given name when it starts with /" do
        object.builder = {:name =>"/custom"}
        info = object.build
        info.first.should == :"/custom"
        info[1].should == :display
      end

      it "should make name /:class_name/:custom_name when it doesn't start with /" do
        object.builder = {:name => "custom"}
        info = object.build
        info.first.should == :"/simple_object/custom"
        info[1].should == :display
      end
    
    end

    it "should use received name" do
      object.builder = {:name=>"/custom"}
      info = object.build("/other_custom")
      info.first.should == :"/other_custom"
    end

  end
end