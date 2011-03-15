require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Lolita::Configuration::List do

  before(:each) do
    @dbi=Lolita::DBI::Base.new(Post)
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
    list.columns.size.should == @dbi.fields.size
    list=Lolita::Configuration::List.new(@dbi){}
    list.columns.size.should == @dbi.fields.size
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
    list=Lolita::Configuration::List.new(@dbi,:per_page=>1)
    list.paginate(1,:per_page=>2).size.should == 2
    list.paginate(1).size.should == 1
  end

  it "should define columns when Symbols are given as args" do
    list=Lolita::Configuration::List.new do
      columns :col1,:col2,:col3
    end
    list.columns.size.should == 3
  end

  it "should sort by one or more columns" do
    list=Lolita::Configuration::List.new do
      column :name=>"col1"
      column :name=>"col2"
      column :name=>"col3"
      desc :col3
    end
    list.asc(:col1).desc(:col2).sort_columns.last.should == [:col2,:desc]
    list.sort_columns[0].should==[:col3,:desc]
  end

  describe "pagination" do
   
   it "should accept Hash params" do
     list=Lolita::Configuration::List.new(@dbi)
     list.paginate({:sort_columns=>[:title,[:body,:asc]]})  
     
   end
   
  end
  it "should move columns to right or left" do
    pending
#    list = Lolita::Configuration::List.new do
#      column :name=>"col1"
#      column :name=>"col2"
#      column :name=>"col3"
#    end
#    list.columns.first.name.should == "col1"
#    list.move(:col2).before(:col1)
#    list.columns[:col_index].move_after(:col1)
#    list.columns.first.name.should == "col2"
#    list.move(:col2).after(:col1)
#    list.columns.first.name.should == "col1"
  end

end

