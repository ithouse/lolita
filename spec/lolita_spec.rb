require File.expand_path(File.dirname(__FILE__) + '/simple_spec_helper')

describe Lolita do

  context "#setup" do
    it "should yield Lolita::BaseConfiguration instance" do
      Lolita.setup do |config|
        config.class.should == Lolita::SystemConfiguration::Base
      end
    end
  end
end

