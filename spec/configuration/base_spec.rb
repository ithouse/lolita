require 'simple_spec_helper'

describe Lolita::Configuration::Base do 
  let(:klass){Lolita::Configuration::Base}
  let(:dbp){Object.new}

  it "should include Lolita::Builder" do 
    klass.ancestors.should include(Lolita::Builder)
  end

  it "should respond to dbp" do 
    klass.new(dbp).should respond_to(:dbp)
  end

  it "should respond to dbi" do 
    klass.new(dbp).should respond_to(:dbi)
  end

  it "should call all args hash part keys as writer methods " do
    klass.any_instance.should_receive(:my_method=).with(1)
    klass.new(dbp, :my_method => 1)
  end
end