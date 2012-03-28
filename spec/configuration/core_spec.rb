require File.expand_path(File.dirname(__FILE__) + '/../simple_spec_helper')

describe Lolita::Configuration::Core do
  let(:klass){Lolita::Configuration::Core}
  let(:dbp_klass){Lolita::DBI::Base}
  let(:dbp){Object.new}
  let(:conf){klass.new(Object)}

  before(:each) do 
    dbp_klass.stub(:create).with(kind_of(Class)).and_return(dbp)
  end

  it "should create new instance without block" do 
    expect{
      klass.new(Object)
    }.not_to raise_error
  end

  it "should create new instance with block" do 
    expect{
      klass.new(Object){}
    }.not_to raise_error
  end

  it "should create dbp instance for received class" do 
    conf = klass.new(Object)
    conf.dbi.should eq(dbp)
  end

  it "should call #generate! when no block is given" do 
    klass.any_instance.should_receive(:generate!).once
    klass.new(Object)
  end

  it "should eval block on instance when block is given" do 
    proc = Proc.new{ "result" }
    klass.any_instance.should_receive(:instance_eval).with(&proc).once
    klass.new(Object,&proc)
  end

  it "should create new list with same DB proxy" do 
    Lolita::Configuration::List.should_receive(:new).with(dbp)
    conf.list.class
  end

  it "should create new list with block" do 
    block = Proc.new{}
    Lolita::Configuration::List.should_receive(:new).with(dbp,&block)
    conf.list(&block).class
  end

  it "should assign new list to @list when instance class is kind of Lolita::Configuration::List" do 
    list = double("list")
    list.stub(:is_a?).with(Lolita::Configuration::List).and_return(true)
    conf.list = list
  end

  it "should create tabs with same DB proxy" do 
    Lolita::Configuration::Tabs.should_receive(:new).with(dbp)
    conf.tabs.class
  end

  it "should create tabs with block" do 
    block = Proc.new{}
    Lolita::Configuration::Tabs.should_receive(:new).with(dbp,&block)
    conf.tabs(&block).class
  end

  it "should create tab with any arguments and add to #tabs" do 
    Lolita::Configuration::Tabs.any_instance.should_receive(:<<).once.and_return(true)
    Lolita::Configuration::Factory::Tab.should_receive(:add).with(dbp,1).and_return(Object.new)
    conf.tab(1)
  end

  it "shoud create tab with any arguments and block" do 
    block = Proc.new{}
    Lolita::Configuration::Tabs.any_instance.should_receive(:<<).once
    Lolita::Configuration::Factory::Tab.should_receive(:add).with(dbp,1,&block)
    conf.tab(1,&block)
  end

  it "should call generator methods when #generate! is called" do 
    klass.class_variable_get(:@@generators).each do |gen_name|
      klass.any_instance.should_receive(gen_name).once
    end
    conf
  end
end

