require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Lolita::Config do
  before(:each) do
    @config = Lolita::Config.new
  end

  it "config should contain system hash" do
    @config.system.is_a? Hash
  end
end

