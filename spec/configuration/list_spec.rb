require 'simple_spec_helper'

class SearchEngine
  def run(*args)
  end
end

describe Lolita::Configuration::List do
  let(:klass){Lolita::Configuration::List}
  let(:dbp_klass){Lolita::DBI::Base}
  let(:dbp){Object.new}
  let(:list){klass.new(dbp)}

  it "should create new with dbp" do
    expect{
      klass.new(dbp)
    }.not_to raise_error
  end

  it "should raise error when no dbp is given" do
    expect{
      klass.new nil
    }.to raise_error(Lolita::UnknownDBPError)
  end

  describe "lolita accessors" do
    it "should have lolita acessor for pagination_method" do
      list.should respond_to(:pagination_method)
      list.should respond_to(:pagination_method=)
    end

    it "should have per_page acessor" do
      list.should respond_to(:per_page)
      list.should respond_to(:per_page=)
    end

    it "should have actions accessor" do
      list.should respond_to(:actions)
      list.should respond_to(:actions=)
    end
  end

  it "should accept block and eval it" do
    block = Proc.new{}
    klass.any_instance.should_receive(:instance_eval).with(&block)
    klass.new(dbp,&block)
  end

  it "should accept options and assign them as attributes" do
    klass.any_instance.should_receive(:test_title=).with("test_title")
    klass.new(dbp,:test_title => "test_title")
  end

  it "should set default attributes values" do
    list.actions.should_not be_empty
    list.per_page.should eq(10)
  end

  it "should populate actions with two default ones" do
    list.actions.should have(2).items
  end

  it "should initialize attribute and eval block after default attributes is initialized" do
    actions_before = nil
    per_page_before = nil
    klass.new(dbp) do
      actions_before = actions.dup
      per_page_before = per_page
    end
    per_page_before.should eq(10)
    actions_before.should be_empty
  end

  it "should allow to add action with name, options and block" do
    action = stub(:name => :name)
    Lolita::Configuration::Action.stub(:new).and_return(action)
    block = Proc.new{}
    list.action :do_stuff, {:key => :value}, &block
    list.actions.should include(action)
  end

  describe "#list" do
    let(:nested_dbp){double("nested_dbp")}
    before(:each) do
      dbp_klass.stub(:create).and_return(nested_dbp)
    end

    it "should return @list when no args and/or block received" do
      dummy_list = stub
      list.instance_variable_set(:@list, dummy_list)
      list.list.should eq(dummy_list)
    end

    it "should check for association and raise error when none is found" do
      dbp.stub(:associations).and_return({})
      expect{
        list.list :dummy_name
      }.to raise_error(Lolita::UnknownDBPError)
    end

    it "should create new dbp object for found assocition class" do
      dummy_association = double("dummy_association")
      dummy_association.stub(:klass).and_return(Object)
      dummy_association.stub(:name).and_return("name")
      dbp.stub(:associations).and_return({'dummy_association' => dummy_association})

      nested_list = double("nested_list")
      Lolita::Configuration::NestedList.should_receive(:new).with(nested_dbp,list,{:association_name => "name"}).and_return(nested_list)
      list.list 'dummy_association'
      list.list.should eq(nested_list)
    end

  end

  describe "#search" do
    let(:dummy_search){double("search")}
    before(:each) do
      dummy_search.stub(:update).and_return(true)
    end

    it "should add search when args and/or block is given" do
      block = Proc.new{}
      Lolita::Configuration::Search.should_receive(:new).with(dbp,:some_thing, &block).and_return(dummy_search)
      list.search :some_thing, &block
    end

    it "should return @search when nothing is received" do
      Lolita::Configuration::Search.stub(:new).and_return(dummy_search)
      list.search :some_args
      list.search.should eq(dummy_search)
    end
  end

  describe "#paginate" do
    it "should call dbp#paginate with arguments and #pagination_method" do
      request = double("request")
      list.pagination_method = :my_dummy_method
      dbp.should_receive(:paginate).with(1,list.per_page, :request => request, :pagination_method => :my_dummy_method).and_return([])
      list.paginate(1, request)
    end

    it "should return pagination results" do
      page = double("page")
      dbp.should_receive(:paginate).and_return(page)
      list.paginate(1)
    end

    it "should notify observers with method name, self and request" do
      request = double("request")
      dbp.stub(:paginate).and_return(nil)
      list.should_receive(:changed)
      list.should_receive(:notify_observers).with(:paginate,list,request)
      list.paginate(1,request)
    end
  end

  describe "#columns=" do
    it "should raise error when something else then Enumerable or Lolita::Configuration::Columns is givne" do
      expect{
        list.columns = Object.new
      }.to raise_error(ArgumentError,"Accepts only Enumerable or Lolita::Configuration::Columns.")
    end

    it "should assign received values to @columns directly when they are kind of Lolita::Configuration::Columns" do
      columns = double("columns")
      columns.should_receive(:parent=).with(list)
      columns.stub(:is_a?).with(Lolita::Configuration::Columns).and_return(true)
      list.columns = columns
      list.columns.should eq(columns)
    end

    it "should iterate through all possible columns and create column with each value" do
      list.should_receive(:column).exactly(3).times.and_return(stub())
      list.columns= [1,2,3]
    end
  end

  describe "#columns" do
    it "should create columns with and/or args, block" do
      block = Proc.new{}
      columns = double("columns")
      columns.should_receive(:parent=).with(list)
      columns.stub(:is_a?).with(Lolita::Configuration::Columns).and_return(true)
      Lolita::Configuration::Columns.should_receive(:new).with(dbp,1,2,3,&block).and_return(columns)
      list.columns(1,2,3,&block)
    end

    it "should return columns when no arguments are given" do
      columns = double("columns")
      list.instance_variable_set(:@columns,columns)
      list.columns.should eq(columns)
    end
  end

  it "should create column with args and block" do
    block = Proc.new{}
    columns = stub("columns")
    list.stub(:columns).and_return(columns)
    columns.should_receive("column").with(1,2,3,&block)
    list.column(1,2,3,&block)
  end

  it "should determine if there is filter defined for list by checking class" do
    list.filter?.should_not be_true
    filter = double("filter")
    filter.stub(:is_a?).with(Lolita::Configuration::Filter).and_return(true)
    list.instance_variable_set(:@filter,filter)
    list.filter?.should be_true
  end

  describe "#filter" do
    let(:filter){double("filter")}
    it "should create filter with arguments and/or block" do
      block = Proc.new{}
      list.stub(:add_observer).and_return(true)
      Lolita::Configuration::Filter.should_receive(:new).with(dbp,1,2,3,&block)
      list.filter(1,2,3,&block)
    end

    it "should return @filter when no arguments is given" do
      list.stub(:add_observer).and_return(true)
      Lolita::Configuration::Filter.should_receive(:new).and_return(filter)
      list.filter(1,2,3)
      list.filter.should eq(filter)
    end

    it "should add observer to filter" do
      Lolita::Configuration::Filter.stub(:new).and_return(filter)
      list.should_receive(:add_observer).with(filter)
      list.filter 1,2
    end
  end

  describe "#by_path" do
    it "should return self when path is empty" do
      list.by_path([]).should eq(list)
    end

    it "should return object list when path starts with l" do
      nested_list = double("nested_list")
      list.stub(:list).and_return(nested_list)
      list.by_path(["l_some_list"]).should eq(nested_list)
    end

    it "should return column with [column_name] list when c_column_name in path" do
      columns = double("columns")
      column = double("column_with_name")
      nested_list = double("nested_list")
      columns.stub(:by_name).with("column_name").and_return(column)
      column.stub(:list).and_return(nested_list)
      list.stub(:columns).and_return(columns)
      list.by_path(["c_column_name"]).should eq(nested_list)
    end

    it "should go through all path array until last object found" do
      path = ["l_some_list","c_column_name","l_other_list"]
      nested_list_1 = double("nested_list_1")
      nested_list_2 = double("nested_list_2")
      nested_list_3 = double("nested_list_3")
      columns = double("columns")
      column = double("column")

      nested_list_1.stub(:columns).and_return(columns)
      nested_list_2.stub(:list).and_return(nested_list_3)
      columns.stub(:by_name).with("column_name").and_return(column)
      column.stub("list").and_return(nested_list_2)
      list.stub(:list).and_return(nested_list_1)

      list.by_path(path).should eq(nested_list_3)
    end
  end

end
