require File.expand_path(File.dirname(__FILE__) + '/../simple_spec_helper')
require 'ruby-debug'

describe Lolita::Configuration::Tabs do
  let(:klass){Lolita::Configuration::Tabs}
  let(:dbp_klass){Lolita::DBI::Base}
  let(:dbp){ Object.new }
  let(:tabs){klass.new(dbp)}

  # before(:each) do
  #   dbp_class.stub(:create).with(kind_of(Class)).and_return(dbp)
  # end

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
    arr = [stub(:fields => [1,2]),stub(:fields => [3,4])]
    tabs.instance_variable_set(:@tabs,arr)
    tabs.fields.should eq([1,2,3,4])
  end

  it "should detect tab by type" do 
    arr = [stub(:type => :content),stub(:type => :image)]
    tabs.instance_variable_set(:@tabs,arr)
    tabs.by_type(:image).should_not be_nil
    tabs.by_type(:not_existing).should be_nil
  end

  it "should return all tabs names" do 
    arr = [stub(:name => "n1"),stub(:name => "n2")]
    tabs.instance_variable_set(:@tabs,arr)
    tabs.names.should eq(["n1","n2"])
  end

  it "should return all associated tabs" do 
    arr = [stub(:dissociate => true),stub(:dissociate => false)]
    tabs.instance_variable_set(:@tabs,arr)
    tabs.associated.should have(1).item
  end

  it "should return all dissociated tabs" do 
    arr = [stub(:dissociate => true),stub(:dissociate => false)]
    tabs.instance_variable_set(:@tabs,arr)
    tabs.dissociated.should have(1).item
  end

  it "should populate self with default tabs" do 
    tabs.should_receive(:build_element).any_number_of_times.and_return(stub())
    tabs.default
    tabs.should have(1).item
  end

  context "adding tabs" do 
    it "should skip factory call when tab is not Hash or Symbol" do 
      tab = stub()
      tabs.tab(tab)
      tabs.first.should == tab
    end

    it "should call factory when tab is Hash" do 
      tab = stub()
      Lolita::Configuration::Factory::Tab.should_receive(:add).and_return(tab)
      tabs.tab({})
      tabs.first.should == tab
    end

    it "should call factory when tab is Symbol" do 
      tab = stub()
      Lolita::Configuration::Factory::Tab.should_receive(:add).and_return(tab)
      tabs.tab(:image)
      tabs.first.should == tab
    end
  end

  # #======

  # it "should create tabs when Array is given" do
  #   tabs=Lolita::Configuration::Tabs.new(@dbi)
  #   tabs.size.should == 0
  # end

  # it "should create tabs when block is given" do
  #   tabs=Lolita::Configuration::Tabs.new(@dbi) {}
  #   tabs.size.should == 0
  # end

  # it "should create tabs when specifid in block" do
  #   tabs=Lolita::Configuration::Tabs.new(@dbi) do
  #     tab(:content)
  #   end
  #   tabs.size.should == 1
  # end

  # it "should create tabs when specified as arguments" do
  #   tabs=Lolita::Configuration::Tabs.new(@dbi,:tabs=>[Lolita::Configuration::Tab::Base.new(@dbi,:content)])
  #   tabs.size.should == 1
  # end

  # it "should create default tabs" do
  #   tabs=Lolita::Configuration::Tabs.new(@dbi) do
  #     default :content,:images
  #   end
  #   tabs.size.should > 0
  # end

  # it "should exclude all default tabs" do
  #   tabs=Lolita::Configuration::Tabs.new(@dbi) do
  #     exclude :all
  #   end
  #   tabs.size.should == 0
  #   tabs.excluded.size.should > 0
  # end

  # it "should exclude specific tabs" do
  #   tabs=Lolita::Configuration::Tabs.new(@dbi)
  #   tabs.exclude :images
  #   tabs.excluded.size.should == 1
  # end

  # it "should add tabs" do
  #   tabs=Lolita::Configuration::Tabs.new(@dbi,:exclude=>:all)
  #   tabs<<:images
  #   tabs<<:content
  #   tabs.size.should == 2
  # end

  # it "should raise error when two same type tabs are added" do
  #   lambda{
  #     tabs=Lolita::Configuration::Tabs.new(@dbi) do
  #       tab :content
  #       tab :content
  #     end
  #   }.should raise_error Lolita::SameTabTypeError
  # end

  # it "should create real tabs when not tab is provided" do
  #   tabs=Lolita::Configuration::Tabs.new(@dbi,:default=>:content)
  #   tabs<<:images
  #   tabs<<:translation
  #   tabs[tabs.size-2].class.should == Lolita::Configuration::Tab::Images
  #   tabs[tabs.size-1].class.should == Lolita::Configuration::Tab::Translation
  # end

  # it "should return all tab names" do
  #   tabs=Lolita::Configuration::Tabs.new(@dbi) do
  #     tab :content
  #   end
  #   tabs.names.size.should > 0
  # end

  # context "tab finding" do
  #   it "should find by type" do
  #     tabs=Lolita::Configuration::Tabs.new(@dbi) do
  #       tab :default do
  #         field :name, :string
  #       end
  #       tab :content
  #     end
  #     tabs.by_type(:content).should_not be_nil
  #   end

  # end
end

