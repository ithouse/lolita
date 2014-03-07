require 'spec_helper'

describe Lolita::Configuration::Filter do

  let(:dbi){Lolita::DBI::Base.new(Post)}

  describe "#initialize" do
    it "should create new filter with block" do
      Lolita::Configuration::Filter.new(dbi) do
      end
    end

    it "should create new filter without block" do
      Lolita::Configuration::Filter.new(dbi)
    end

    it "should give fields as arguments" do
      list=Lolita::Configuration::List.new(dbi)
      list.filter :name, :is_public
      list.filter.fields.size.should == 2
    end
  end

  describe "#field" do
    it "add field" do
      filter = Lolita::Configuration::Filter.new(dbi) do
        field :title
      end
      filter.fields.first.name.should eq(:title)
    end

    it "add field with block" do
      filter = Lolita::Configuration::Filter.new(dbi) do
        field :name do
          type :integer
        end
      end
      filter.fields.first.type.should == "integer"
    end
  end

  describe "#fields" do
    it "add multiple fields" do
      filter=Lolita::Configuration::Filter.new(dbi) do
        fields :name, :is_public, :not_public
      end
      filter.fields.size.should == 3
    end

    it "should add some fields with block" do
      filter=Lolita::Configuration::Filter.new(dbi) do
        fields :name, :is_public do
          type :integer
        end
        field :created_at, :time
      end
      filter.fields.size.should == 3
      filter.fields[0].type.should == "integer"
      filter.fields[1].type.should == "integer"
      filter.fields[2].type.should == "time"
    end
  end

  describe "#search" do
    let(:list){ Lolita::Configuration::List}

    it "should filter with default search" do
      Fabricate(:post, title: "Big fish")
      2.times { Fabricate(:post) }
      list_conf = list.new(dbi) do
        filter :title
      end
      list_conf.paginate(1).should have(3).items
      request = Object.new
      request.class_eval do
        def params
          {filter: {title: "Big fish"}}
        end
      end
      list_conf.paginate(1, request).should have(1).item
    end

    it "should filter with custom search" do
      3.times {|i| Fabricate(:post, price: i * 5) }
      Post.class_eval do
        def self.custom_filter query, request
          where(price: 10)
        end
      end
      list_conf = list.new(dbi) do
        filter do
          field :tags
          search :custom_filter
        end
      end
      list_conf.paginate(1).should have(3).items
      request = Object.new
      request.class_eval do
        def params
          {filter: {price: 5}}
        end
      end
      list_conf.paginate(1,request).should have(1).item
      list_conf.paginate(1,request).first.price.should eq(10)
    end
  end

  describe "#resource" do
    let(:filter){ Lolita::Configuration::Filter.new(dbi, :name ) }
    let(:params){ {} }
    subject do
      tags = %w(Android Linux Windows).map{|name| Fabricate(:tag, name: name )}
      filter.resource(params)
    end

    context "reflections" do
      let(:params){ {post: {tag_ids: ["", Tag.where(name: "Android").first.id]}} }
      let(:filter){ Lolita::Configuration::Filter.new(dbi, :tag) }
      it "recognizes" do
        subject.tags.should have(1).item
      end
    end

    context "simple attributes" do
      let(:params){ {post: {title: "MyName" }} }
      let(:filter){ Lolita::Configuration::Filter.new(dbi, :title ) }
      it "recognizes" do
        subject.title.should eq("MyName")
      end
    end

    it "should be persisted" do
      subject.should be_persisted
    end
  end
end
