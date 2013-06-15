# To change this template, choose Tools | Templates
# and open the template in the editor.

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Lolita::Mapping do

	it "should store options" do
		mapping=Lolita::Mapping.new(:posts)
		mapping.to.should == Post
		mapping.plural.should == :posts
		mapping.singular.should == :post
		mapping.path.should == "lolita"
		mapping.controllers[:posts].should == "lolita/posts"
	end

	context "url_name" do
		it "should start with lolita when no path is given" do
			mapping=Lolita::Mapping.new(:posts)
			mapping.url_name.should=="lolita_posts"
		end

		it "should start with given path" do
			mapping=Lolita::Mapping.new(:posts,:path=>"my_admin")
			mapping.url_name.should == "my_admin_posts"
		end
	end
end

