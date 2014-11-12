require 'simple_spec_helper'

describe Lolita::Configuration::Tabs do
  let(:klass){ Lolita::Configuration::Tabs }
  let(:dbp_klass){ Lolita::DBI::Base }
  let(:dbp){ Object.new }
  let(:tabs){ klass.new(dbp) }

  it "should set attributes from args to tabs" do
    args = [1,2,3]
    klass.any_instance.should_receive(:set_attributes).with(*args)
    klass.new(dbp,*args)
  end

  it "should eval block when given" do
    block = Proc.new{}
    klass.any_instance.should_receive(:instance_eval).with(&block)
    klass.new(dbp,&block)
  end

  it "should initialize default attributes when instance is created" do
    tabs = klass.new(dbp)
    tabs.should be_empty
    tabs.tab_types.should eq([:content])
  end

  it "should be enumerable and yield each tab at once" do
    tabs.instance_variable_set(:@tabs, [1,2,3])
    tabs.each_with_index do |tab,index|
      tab.should eq(index+1)
    end
  end

  it "should create content tab when accessing any tab and none is given" do
    tabs.should_receive(:create_content_tab)
    tabs.any?
  end

  it "should accept collection of tabs and iterate through them and assign to itself through builder" do
    tabs.should_receive(:build_element).twice
    tabs.tabs= [1,2]
  end

  it "should raise ArgumentError when assigned tabs is not collection" do 
    expect{
      tabs.tabs = Object.new
    }.to raise_error(ArgumentError)
  end

  it "should add tab with no args" do
    klass.any_instance.should_receive(:build_element).twice.and_return(1)
    tabs.tab
    tabs.should have(1).item
  end

  it "should return all field of each tab" do
    arr = [double(fields: [1,2]), double(fields: [3,4])]
    tabs.instance_variable_set(:@tabs,arr)
    tabs.fields.should eq([1,2,3,4])
  end

  it "should detect tab by type" do
    arr = [double(type: :content), double(type: :image)]
    tabs.instance_variable_set(:@tabs, arr)
    tabs.by_type(:image).should_not be_nil
    tabs.by_type(:not_existing).should be_nil
  end

  it "should return all tabs names" do
    arr = [double(name: "n1"), double(name: "n2")]
    tabs.instance_variable_set(:@tabs,arr)
    tabs.names.should eq(["n1","n2"])
  end

  it "should return all associated tabs" do
    arr = [double(dissociate: true), double(dissociate: false)]
    tabs.instance_variable_set(:@tabs,arr)
    tabs.associated.should have(1).item
  end

  it "should return all dissociated tabs" do
    arr = [double(dissociate: true), double(dissociate: false)]
    tabs.instance_variable_set(:@tabs,arr)
    tabs.dissociated.should have(1).item
  end

  it "should populate self with default tabs" do
    tabs.stub(:build_element).and_return(double())
    tabs.default
    tabs.should have(1).item
  end

  context "adding tabs" do
    it "should skip factory call when tab is not Hash or Symbol" do
      tab = double()
      tabs.tab(tab)
      tabs.first.should eq(tab)
    end

    it "should call factory when tab is Hash" do
      tab = double()
      Lolita::Configuration::Factory::Tab.stub(:add).and_return(tab)
      tabs.tab({})
      tabs.first.should eq(tab)
    end

    it "should call factory when tab is Symbol" do
      tab = double()
      Lolita::Configuration::Factory::Tab.stub(:add).and_return(tab)
      tabs.tab(:image)
      tabs.first.should eq(tab)
    end
  end

end

