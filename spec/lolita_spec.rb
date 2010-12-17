require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Lolita do

  it "should yield itself" do
    Lolita.setup do |config|
      config.should == Lolita
    end
  end
end

