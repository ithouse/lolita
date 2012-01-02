require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Lolita::RestController do
  render_views
  
  before(:each) do
    @request.env["lolita.mapping"]=Lolita.mappings[:post]
  end

  describe "hooks" do
    it "should call hooks on #index action" do
      @controller.class.class_variable_set(:"@@temp",1)
      @controller.before_index do
        @@temp=2
      end
      get :index
      @controller.class.class_variable_get(:"@@temp").should == 2
    end
  end

  it "should render list component for index action" do
    get :index
    response.should render_template("index")
  end

  it "should overwrite list component body_cell" do
    pending "Need to be seperated from whole project"
    Factory.create(:post)
    get :index
    response.body.should =~/overwritten cell/
  end

  it "should render tabs for new resource" do
    get :new
    response.body.should =~/select|input/
  end

  it "should change name of field's label to 'bar' if title 'bar' given in fields configuration" do
    tab = Post.lolita.tabs.first
    tab.type.should == :content
    tab.fields.by_name(:title).title = "foobar"
    get :new
    response.body.should match(/foobar/i)
  end

  it "should display inline error messages if validations fail"

  it "should display all error messages at top of from if a validations fail"

  it "should use field.title instead of field.name when displaying all error messages at top of form"

  describe "nested lists" do

    it "should have nested lists for columns" do
      pending "Need to fix this"
      get :index
      response.body.should match(/tr.*class\s*=.*with-nested-list.*data-nested-list-url/)
    end

    it "should have nested lists for whole row" do
      pending "Need to fix this"
      @request.env["lolita.mapping"]=Lolita.mappings[:category]
      get :index
      response.body.should match(/tr.*class.*with-nested-list.*data-nested-list-url/)
    end

    it "should have nested list for nested lists" do
      pending "Need to fix this"
      categories = (1..5).to_a.map{|i|
        Factory.create(:category)
      }
      2.times{Factory.create(:post, :category => categories.first)}
      get :index, {:nested => {"category_id" => categories.last}}
      response.body.should_not match(/tr/)
      get :index, {:nested => {"category_id" => categories.first}}
      response.body.scan(/<tr>/).should have(2).items
      response.body.should match(/td.*class.*with-nested-list/)
    end
  end

end

