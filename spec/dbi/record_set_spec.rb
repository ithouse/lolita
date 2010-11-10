# To change this template, choose Tools | Templates
# and open the template in the editor.

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Lolita::DBI::RecordSet do
  before(:each) do
    @dbi=Lolita::DBI::Base.new(TestClass1)
  end

  it "should desc" do
    # TODO
  end
end

