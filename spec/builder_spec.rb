require File.expand_path(File.dirname(__FILE__) + '/simple_spec_helper')

class SimpleObject 
  include Lolita::Builder
end

describe Lolita::Builder do

  let(:object){SimpleObject.new}

  describe "#build" do
    it "should return default component information when no params passed" do
      info=object.build
      info.first.should == :"/simple_object"
      info[1].should == :display
      info.last.should have_key(:simple_object)
    end

    context "with instance builder" do
      it "should use given one" do
        object.builder="custom"
        info=object.build
        info.first.should==:"/simple_object/custom"
        info[1].should == :display
      end

      it "should use that what #build receive" do
        object.builder="custom"
        info=object.build("other")
        info.first.should == :"/simple_object/other"
        info[1].should == :display
      end
    end

    it "should accept empty name" do
      info=object.build("",:list)
      info.first.should == :"/simple_object"
      info[1].should == :list
    end

  end
end