require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Lolita::DBI::Base do
#  before(:each) do
#    @base = Base.new
#  end

  it "should raise error when not ORM class is given" do
    lambda{
      Lolita::DBI::Base.new(String)
    }.should raise_error Lolita::NotORMClassError
    lambda{
      Lolita::DBI::Base.new()
    }.should raise_error ArgumentError
  end

  it "should detect adapter" do
    dbi=Lolita::DBI::Base.new(Post)
    dbi.klass.should == Post
    Lolita::DBI::Base.adapters.should include(dbi.adapter_name)
  end

  it "should connect adapter" do
    dbi=Lolita::DBI::Base.new(Post)
    lambda{
      dbi.fields
    }.should_not raise_error
  end

  it "should display all adapter available" do
    Lolita::DBI::Base.adapters.size.should > 0
  end

  it "should order with paginate" do
    Post.destroy_all
    Factory.create(:post, :title => "Apple")
    Factory.create(:post, :title => "Banana")
    Factory.create(:post, :title => "Cucumber")
    dbi=Lolita::DBI::Base.new(Post)
    dbi.paginate(:per_page => 3, :page => 1, :sort => [[:title,:desc]]).map(&:title).should == %w(Cucumber Banana Apple)
    dbi.paginate(:per_page => 3, :page => 1, :sort => [[:title,:asc]]).map(&:title).should == %w(Apple Banana Cucumber)
  end
end

