require 'spec_helper'

describe Lolita::Search::Simple do
  let(:dbi){Lolita::DBI::Base.create(Post)}

  it "should accept search method" do
    search = Lolita::Search::Simple.new(dbi,:custom_search)
    search.search_method.should == :custom_search
  end

  it "should create new search without search method" do
    search = Lolita::Search::Simple.new(dbi)
    search.search_method.should be_nil
  end

  describe "#run" do
    let(:search){Lolita::Search::Simple.new(dbi)}

    it "should run default search when no search method is provided" do
      pending "think that map_reduce should be fixed"
      Fabricate(:post,:title => "moonwalker")
      search = Lolita::Search::Simple.new(dbi)
      search.run("moon").size.should == 1
    end

    it "should accept custom dbi for search" do
      Fabricate(:category, :name => "special_text")
      search.run("special_text").should be_empty
      search.run("special_text",Object.new,Lolita::DBI::Base.create(Category)).should have(1).item
    end

    it "should run custom search when search method is provided" do
      search = Lolita::Search::Simple.new(dbi,:custom_search)
      post = Fabricate(:post,:expire_date => 2.days.since)
      results = search.run("")
      results.should have(1).item
      results.first.should == post
    end

    it "should use only given fields when they are presented" do
      search = Lolita::Search::Simple.new(dbi,:fields => [:body])
      Fabricate(:post,:title => "only_in_title")
      search.run("only_in_title").should have(0).items
      search2 = Lolita::Search::Simple.new(dbi,:fields => [:title])
      search2.run("only_in_title").should have(1).item
    end
  end
end