require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Lolita::RestController do
  render_views

  before(:each) do
    @controller.request.env["lolita.mapping"]=Lolita.mappings[:post]
  end

  it "should add custom assets to Lolita" do
    Lolita.application.assets += ["lolita_js_extensions.js"]
    get :index
    response.body.should =~/lolita_js_extensions.js/
  end
end