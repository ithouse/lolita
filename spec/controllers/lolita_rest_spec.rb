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
end

