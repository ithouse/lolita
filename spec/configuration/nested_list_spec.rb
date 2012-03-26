require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Lolita::Configuration::NestedList do
  let(:dbi){ Lolita::DBI::Base.create(Post) }
  let(:comment_dbi){ Lolita::DBI::Base.create(Comment) }
  let(:list_class){ Lolita::Configuration::List }
  let(:nested_list_class){ Lolita::Configuration::NestedList }

  it "should create new nested list" do
    expect do
      Lolita::Configuration::NestedList.new(comment_dbi,list_class.new(dbi))
    end.not_to raise_error
  end 

  it "should raise error when no list or nested list or column is given" do
    expect do
      Lolita::Configuration::NestedList.new(comment_dbi,nil)
    end.to raise_error(Lolita::ParentNotAListError)
  end

  it "should receive List, NestedList or Column as parent" do
    list_object = Lolita::Configuration::List.new(dbi)
    column_object = Lolita::Configuration::Column.new(dbi,:name => :title)

    list = nested_list_class.new(dbi, list_object)
    list.parent.should == list_object
    list = nested_list_class.new(dbi, column_object)
    list.parent.should == column_object
    nested_list_object = Lolita::Configuration::NestedList.new(dbi,list_object)
    list = nested_list_class.new(dbi, nested_list_object)
    list.parent.should == nested_list_object
  end

  it "should collect all parents " do
    list = list_class.new(dbi)
    nlist1 = nested_list_class.new(dbi,list)
    nlist2 = nested_list_class.new(dbi,nlist1)
    nlist3 = nested_list_class.new(dbi,nlist2)
    nlist3.parents.should == [nlist2,nlist1,list]
    nlist2.parents.should == [nlist1,list]
    nlist1.parents.should == [list]
  end

  it "should return depth of list" do
    list = list_class.new(dbi)
    nlist1 = nested_list_class.new(dbi,list)
    nlist2= nested_list_class.new(dbi,nlist1)
    nlist1.depth.should == 1
    nlist2.depth.should == 2
  end

  it "should have list association name" do
    main_list = list_class.new(dbi) do
      list(:comments){}
    end
    main_list.list.association_name.should == :comments
  end

  it "should have association" do
    main_list = list_class.new(dbi) do
      list(:comments){}
    end
    main_list.list.association.name.should == dbi.associations[:comments].name
  end
  
  it "should return root" do
    list = list_class.new(dbi)
    nlist1 = nested_list_class.new(dbi,list)
    nlist2 = nested_list_class.new(dbi,nlist1)
    nlist2.root.should == list
  end
  
  it "should create mapping for DBI class" do
    list = list_class.new(dbi)
    nlist = nested_list_class.new(comment_dbi,list, :association_name => "comments")
    nlist.mapping.to.should == Comment
  end

  it "should allow to define sublist in any depth" do
    dbi = Lolita::DBI::Base.create(Category)

    new_list = list_class.new(dbi) do
      list(:posts) do
        column :title
        list(:comments) do
          column :body
        end
      end
    end

    new_list.list.list.columns.should have(1).item
  end

  it "should create options for nested lists" do
    dbi = Lolita::DBI::Base.create(Category)

    new_list = list_class.new(dbi) do
      list(:posts) do
        column :title
        list(:comments) do
          column :body
        end
      end
    end

    record = Fabricate(:category)
    post = Fabricate(:post)
    new_list.list.nested_options_for(record)[:nested].keys.should == ["category_id",:parent,:path]
    new_list.list.list.nested_options_for(post)[:nested].keys.should == ["post_id",:parent,:path]
  end
end