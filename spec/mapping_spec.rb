# To change this template, choose Tools | Templates
# and open the template in the editor.

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Lolita::Mapping do

  it "should store options" do
    mapping=Lolita::Mapping.new(:posts)
    mapping.to.should == Post
    mapping.plural.should == :posts
    mapping.singular.should == :post
    mapping.path.should == "posts"
  end
end

