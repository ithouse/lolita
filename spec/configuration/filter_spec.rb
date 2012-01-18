require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Lolita::Configuration::Filter do

  let(:dbi){Lolita::DBI::Base.new(Post)}

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
  
  it "should add default search field if none is given" do
    filter=Lolita::Configuration::Filter.new(dbi)
    filter.fields.size.should == 1
    filter=Lolita::Configuration::Filter.new(dbi){}
    filter.fields.size.should == 1
  end

  it "should add some fields" do
    filter=Lolita::Configuration::Filter.new(dbi) do
      fields :name, :is_public, :not_public
    end
    filter.fields.size.should == 3
  end

  it "should add some field with block" do
    filter=Lolita::Configuration::Filter.new(dbi) do
      field :name do
        type :integer
      end
    end
    filter.fields.first.type.should == "integer"
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

  # it "should return right values" do
  #   Category.delete_all
  #   3.times{ Factory.create(:category)}
  #   filter=Lolita::Configuration::Filter.new(dbi) do
  #     field :category
  #     field :some_type, :array, :values => %w(a b c)
  #   end
  #   options = filter.options_for_select(filter.fields.first)
  #   options.size.should == 3
  #   options.first.first.should be_an(String)
  #   options.first.last.should be_an(BSON::ObjectId)
  #   options = filter.options_for_select(filter.fields.last)
  #   options.size.should == 3
  #   options.should == %w(a b c)
  # end

  it "should filter results for boolean" do
    Factory.create(:post, :is_public => true)
    Factory.create(:post, :is_public => true)
    Factory.create(:post, :is_public => false)

    filter=Lolita::Configuration::Filter.new(dbi) do
      field :is_public
    end

    dbi.filter(:is_public => 1).size.should == 2
    dbi.filter(:is_public => 0).size.should == 1
  end

  it "should filter results for belongs_to" do
    c1 = Factory.create(:category, :name => "Linux")
    c2 = Factory.create(:category, :name => "Android")
    p1=Factory.create(:post, :category => c1)
    p2=Factory.create(:post, :category => c1)
    p3=Factory.create(:post, :category => c2)

    filter=Lolita::Configuration::Filter.new(dbi) do
      field :tags
    end
    dbi.filter(:category_id => c1.id).size.should == 2
    dbi.filter(:category_id => c2.id).size.should == 1
  end

  it "should filter results for has_and_belongs_to_many" do
    tag1 = Factory.create(:tag, :name => "Linux")
    tag2 = Factory.create(:tag, :name => "Android")
    p1=Factory.create(:post, :tags => [tag1,tag2])
    p2=Factory.create(:post, :tags => [tag1,tag2])
    p3=Factory.create(:post, :tags => [tag1])

    filter=Lolita::Configuration::Filter.new(dbi) do
      field :tags
    end
    dbi.filter(:tag_ids => tag1.id).size.should == 3
    dbi.filter(:tag_ids => tag2.id).size.should == 2
  end

  describe "Filtering list" do
    let(:list){ Lolita::Configuration::List}

    it "should filter with default filters" do
      tags = %w(Android Linux Windows).map{|name| Factory.create(:tag, :name => name )}
      3.times {|i| Factory.create(:post,:tags => [tags[i]])}

      list_conf = list.new(dbi) do
        filter do
          field :tags
        end
      end
      list_conf.paginate(1).should have(3).items
      request = Object.new
      request.class_eval do
        def params
          {:filter => {:tag_ids => Tag.where(:name => 'Android').first.id}}
        end
      end
      list_conf.paginate(1,request).should have(1).items
    end
    
    it "should filter with custom search" do
      tags = %w(Android Linux Windows).map{|name| Factory.create(:tag, :name => name )}
      3.times {|i| Factory.create(:post,:tags => [tags[i]])}
      Post.class_eval do
        def self.custom_filter query,request
          where(:tag_ids.in => Tag.where(:name.in => ['Android','Linux']).map(&:id))
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
          {:filter => {:tag_ids => Tag.where(:name => 'Android').first.id}}
        end
      end
      list_conf.paginate(1,request).should have(2).items
    end
  end
end