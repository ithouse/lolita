require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Lolita::Configuration::Page do
  let(:dbi){ Lolita::DBI::Base.new(Post)}
  
  it "should sort by one or more columns" do
    page=Lolita::Configuration::Page.new(dbi)
    page.asc(:col1).desc(:col2).sort_columns.last.should == [:col2,:desc]
    page.sort_columns[0].should==[:col1,:asc]
  end

  describe "pagination" do
   
   it "should accept Hash params" do
     page=Lolita::Configuration::Page.new(dbi)
     page.paginate({:sort_columns=>[:title,[:body,:asc]]},:hold=>true)  
   end
   
  end
end