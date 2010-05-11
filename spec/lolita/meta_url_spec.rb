require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Lolita::MetaUrl do
  before(:each) do
    #$lolita_config = Lolita::Config.new
  end

  #TODO
  # 1) need to generate a demo model with associated meta_data
  # 2) need to generate a demo model with a slug field
  # 3) need to verify that generated url's are correct
  # 4) need to verify that requesting the url's correctly initializes the variables for the show action


  it "should recognize if an object has a slug and place this insted of the id in url's" do
    pending("need to create models, controllers and data for testing")
  end

  it "should recognize if an object has meta_data.url and place this insted of the id in url's" do
    pending("need to create models, controllers and data for testing")
  end

  it "should find the object associated with the slug and put it in the @object variable when the accorging url is requested" do
    pending("need to create models, controllers and data for testing")
  end

  it "should find the object associated with meta_data.url and put it in the @object variable when the accorging url is requested" do
    pending("need to create models, controllers and data for testing")
  end

end