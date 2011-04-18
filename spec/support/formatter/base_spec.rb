require File.expand_path(File.dirname(__FILE__) + '/../../simple_spec_helper')

describe Lolita::Support::Formatter::Base do
  let(:klass){Lolita::Support::Formatter::Base}

  context "create new" do

    it "should accept value as format" do
      formatter=klass.new("%Y-%m")
      formatter.format.should == "%Y-%m"
    end

    it "should accept block" do
      formatter=klass.new do |value|
        value**2
      end
      formatter.block.should_not be_nil
    end
  end

  context "calling formatter" do
    it "should call block" do
      formatter=klass.new do |value|
        value.to_i+1
      end
      formatter.with(2).should == 3
    end

    it "should try to call #format method on given value" do
      formatter=klass.new("M")
      object=mock(Object)
      object.stub!(:format).and_return(1)
      object.stub!(:respond_to?).with(:format).and_return(true)
      formatter.with(object).should == 1
    end

    it "should convert received value to string and call #unpack" do
      formatter=klass.new('C')
      formatter.with("\100").should == [64]
    end
  end
end
