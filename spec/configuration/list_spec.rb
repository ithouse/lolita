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
    list=list_class.new(@dbi,:per => 1)
    list.paginate(1,Object.new).to_a.size.should == 1
  end

  it "should define columns when Symbols are given as args" do 
    list = list_class.new(@dbi) do
      columns :col1,:col2,:col3
    end
    list.columns.should have(3).items
  end

  it "may have parent" do
    some_object = Object.new
    list = list_class.new(@dbi, :parent => some_object)
    list.parent.should == some_object
  end

  it "should collect all parents " do
    list = list_class.new(@dbi)
    list2 = list_class.new(@dbi,:parent => list)
    list3 = list_class.new(@dbi, :parent => list2)
    list3.parents.should == [list2,list]
    list2.parents.should == [list]
    list.parents.should == []
  end

  it "should return depth of list" do
    list = list_class.new(@dbi)
    list2= list_class.new(@dbi,:parent => list)
    list.depth.should == 1
    list2.depth.should == 2
  end

  describe "search" do
    let(:list){ list_class.new(@dbi,:per => 10) }

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

    it "should allow to define sublist with association name or adapter" do
      list_class.new(@dbi) do
        list(:comments){}
      end

      list_class.new(@dbi) do
        list(Lolita::DBI::Base.create(Comment))
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

    it "should allow to define sublist in any depth" do
      dbi = Lolita::DBI::Base.create(Category)

      new_list = list_class.new(dbi) do
        list(:posts) do
          column :title
          list(:comments) do
            column :body
          end
        end
      end

      new_list.list.list.columns.should have(1).item
    end

  end

end

