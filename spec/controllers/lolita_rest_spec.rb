require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Lolita::RestController do
  render_views
  
  before(:each) do
    @controller.request.env["lolita.mapping"]=Lolita.mappings[:post]
  end

  it "should render list component for index action" do
    get :index
    response.should render_template("index")
  end

  it "should overwrite list component body_cell" do
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
    response.body.should =~/foobar/
  end

  it "should display inline error messages if validations fail"

  it "should display all error messages at top of from if a validations fail"

  it "should use field.title instead of field.name when displaying all error messages at top of form"

end

