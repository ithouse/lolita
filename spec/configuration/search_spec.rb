require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

class CustomSearch
  def initialize(dbi)
    @dbi = dbi
  end
  def run(query,request=nil)
    @dbi.klass.where(:title => query)
  end
end
describe Lolita::Configuration::Search do
  let(:dbi){Lolita::DBI::Base.create(Post)}

  it "should create search proxy with only dbi" do
    search = Lolita::Configuration::Search.new(dbi)
    search.with.class.to_s.should match(/Lolita::Search::Simple/)
  end

  it "should create search with true argument" do
    search = Lolita::Configuration::Search.new(dbi,true)
    search.with.class.to_s.should match(/Lolita::Search::Simple/)
  end

  it "should accept attributes through hash argument" do
    search = Lolita::Configuration::Search.new(dbi,:with => CustomSearch)
    search.with.class.to_s.should match(/CustomSearch/)
  end

  it "should accept block " do
    search = Lolita::Configuration::Search.new(dbi) do 
      with CustomSearch
    end
    search.with.class.to_s.should match(/CustomSearch/)
  end

  describe "#run" do

    it "should run search on custom class" do
      Fabricate(:post, :title => "my_title")
      search = Lolita::Configuration::Search.new(dbi, :with => CustomSearch)
      search.run("my_title",Object.new).size.should == 1
    end
  end
end