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

  let(:list_class){Lolita::Configuration::List}

  it "should create new list with block" do
    Lolita::Configuration::List.new(@dbi) do

    end
  end

  it "should create new list without block" do
    Lolita::Configuration::List.new(@dbi)
  end

  it "should generate columns if none is given" do
    list=Lolita::Configuration::List.new(@dbi)
    list.columns.should have(@dbi.fields.reject{|f| f.technical?}.size).items
    list=Lolita::Configuration::List.new(@dbi){}
    list.columns.should have(@dbi.fields.reject{|f| f.technical?}.size).items
  end

  it "should not generate columns if one or more is given" do
    list=list_class.new(@dbi,:columns=>[{:name=>"C1"}])
    list.columns.should have(1).item
    list=list_class.new(@dbi) do
      column :name=>"Col1"
      column :name=>"col3"
      column do
        name "col2"
        title "Column two"
      end
    end
    list.columns.should have(3).items
  end

  it "should get records for list page" do
    1.upto(5) { Factory.create(:post)}
    list=list_class.new(@dbi,:per_page => 1)
    list.paginate(1,Object.new).to_a.size.should == 1
  end

  it "should define columns when Symbols are given as args" do 
    list = list_class.new(@dbi) do
      columns :col1,:col2,:col3
    end
    list.columns.should have(3).items
  end

  describe "search" do
    let(:list){ list_class.new(@dbi,:per_page => 10) }

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

  describe "sublist" do

    it "should allow to define sublist with association name" do
      list_class.new(@dbi) do
        list(:comments){}
      end
    end

    it "should raise error when no DBI is given or found through association" do
      expect{
        list_class.new(@dbi) do
          list{}
        end
      }.to raise_error(Lolita::UnknownDBIError)

      expect{
        list_class.new(@dbi) do
          list(:title)
        end
      }.to raise_error(Lolita::UnknownDBIError)
    end

  end

end

