require File.expand_path(File.dirname(__FILE__) + '/../../simple_spec_helper')

describe Lolita::Extensions::Authorization::Proxy do 
  let(:klass){ Lolita::Extensions::Authorization::Proxy }
  let(:proxy){ klass.new(Object.new,{}) }
  
  it "should create new proxy" do
    expect do
      klass.new(Object.new,{})
    end.not_to raise_error
  end

  it "should have #can?" do
    proxy.respond_to?(:can?).should be_true
  end
  
  it "should have #cannot?" do
    proxy.respond_to?(:cannot?).should be_true
  end

  it "should have #authorize!" do
    proxy.respond_to?(:authorize!).should be_true
  end

  it "should have #current_ability" do
    proxy.respond_to?(:current_ability).should be_true
  end

end