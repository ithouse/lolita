require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

class SearchEngine
  def run(*args)
  end
end

describe Lolita::Configuration::List do

  before(:each) do
    @dbi=Lolita::DBI::Base.create(Post)
  end
  
  after(:each) do
    @recs||=[]
    @recs.each{|r| r.destroy}
  end

  it "should create new list with block" do
    Lolita::Configuration::List.new(@dbi) do

    end
  end

  it "should create new list without block" do
    Lolita::Configuration::List.new(@dbi)
  end

  it "should generate columns if none is given" do
    list=Lolita::Configuration::List.new(@dbi)
    list.columns.size.should == @dbi.fields.reject{|f| f.technical?}.size
    list=Lolita::Configuration::List.new(@dbi){}
    list.columns.size.should == @dbi.fields.reject{|f| f.technical?}.size
  end

  it "should not generate columns if one or more is given" do
    list=Lolita::Configuration::List.new(@dbi,:columns=>[{:name=>"C1"}])
    list.columns.size.should == 1
    list=Lolita::Configuration::List.new(@dbi) do
      column :name=>"Col1"
      column :name=>"col3"
      column do
        name "col2"
        title "Column two"
      end
    end
    list.columns.size.should==3
  end

  it "should get records for list page" do
    1.upto(5) { Factory.create(:post)}
    list=Lolita::Configuration::List.new(@dbi,:per => 1)
    list.paginate(1,Object.new).to_a.size.should == 1
  end

  it "should define columns when Symbols are given as args" do
    list=Lolita::Configuration::List.new do
      columns :col1,:col2,:col3
    end
    list.columns.size.should == 3
  end

  describe "search" do
    let(:list){ Lolita::Configuration::List.new(@dbi,:per => 10) }

    it "should define default search by passing true" do
      list.search true
      list.search.class.to_s.should match(/Lolita::Configuration::Search/)
    end

    it "should define search with block" do
      list.search do 
        with SearchEngine.new
      end
      list.search.class.to_s.should match(/Lolita::Configuration::Search/)
    end
  end

end

