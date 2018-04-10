require File.expand_path(File.dirname(__FILE__) + '/simple_spec_helper')

describe Lolita::Register do
  let(:register){ Lolita::Register.new }
  it "should create new" do
    expect do
      Lolita::Register.new
    end.not_to raise_error
  end

  it "should set new key" do
    register.set(:test, 1).should be_truthy
  end

  it "should get key" do
    register.set(:test, 1)
    register.get(:test).should == 1
    register.get(:not_existing_key).should be_nil
  end
  
  it "should get with options" do
    register.set(:test, 1, :foo => :bar)
    register.set(:test_without_options, 1)
    register.get_with_options(:test).should have(2).items
    register.get_with_options(:test_without_options).should have(1).item
  end

  it "should set key with options" do
    register.set(:test, 1, :foo => :bar).should be_truthy
  end
  
  context "filter" do
    it "should accept only key" do
      register.set(:test, 1, :foo => :bar)
      register.filter(:test).should == [[1, {:foo=>:bar}]]
    end

    it "should accept key and options" do
      register.set(:test, 1, :foo => :bar)
      register.filter(:test, :foo => 0).should be_empty
      register.filter(:test, :foo => :bar).should have(1).item
    end

    it "should accept only options" do
      register.set(:test, 1, :foo => :bar)
      register.filter(:foo => 0).should be_empty
      register.filter(:foo => :bar).should have(1).item
    end
  end
end
