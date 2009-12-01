require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Lolita::Config do
  before(:each) do
    $lolita_config = Lolita::Config.new
  end

  it "config should respond to correct object types" do
    Lolita.config.system.should be_kind_of(Hash)
    Lolita.config.system(:domain).should be_kind_of(String)
    Lolita.config.system(:not_existant_key).should be_kind_of(NilClass)
    Lolita.config.system(:geokit).should_not be_nil
    Lolita.config.email(:smtp_settings, :port).should be_kind_of(Integer)
  end
end

