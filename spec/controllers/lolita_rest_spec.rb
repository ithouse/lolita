# To change this template, choose Tools | Templates
# and open the template in the editor.

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Lolita::RestController do
  render_views
  before(:each) do
    
  end

  it "should return" do
    @controller.request.env["lolita.mapping"]=Lolita.mappings[:post]
    get :new
    response.body.should match(/rails_app/)
  end
end

