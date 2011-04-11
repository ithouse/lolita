require File.expand_path(File.dirname(__FILE__) + '/simple_spec_helper')


class MyClass
  def self.value(value=nil)
    @value=value if value
    @value
  end

  attr_accessor :name
  def initialize
    self.fire(:after_init)
  end

  def save
    self.fire(:before_save)
  end
end

class Counter
  def self.set(val)
    @value=val
  end

  def self.get
    @value
  end
end
describe Lolita::Hooks do
  after(:each) do
    MyClass.clear_hooks if MyClass.respond_to?(:clear_hooks)
    Counter.clear_hooks if Counter.respond_to?(:clear_hooks)
    MyClass.value(0)
  end

  it "should be possible to define hooks for class" do
    MyClass.send(:include, Lolita::Hooks)
    MyClass.add_hook(:after_load)
    MyClass.hooks.should have(1).item
  end

  it "should accept callback for class" do
    MyClass.send(:include, Lolita::Hooks)
    MyClass.add_hook(:after_load)
    MyClass.after_load do
      1+1
    end
    MyClass.callbacks[:after_load][:blocks].should have(1).item
    MyClass.callbacks[:after_load][:methods].should have(0).items
  end

  it "should append methods and blocks to callbacks" do
    MyClass.send(:include,Lolita::Hooks) 
    MyClass.add_hook(:after_load)
    MyClass.after_load {}
    MyClass.after_load {}
    MyClass.after_load :method
    MyClass.after_load :other_method
    MyClass.callbacks[:after_load][:blocks].should have(2).items
    MyClass.callbacks[:after_load][:methods].should have(2).items
  end
    
  context "Firing callbacks" do

    before(:each) do
      MyClass.send(:include, Lolita::Hooks)
      MyClass.add_hook(:after_load)
      MyClass.add_hook(:after_init)
      MyClass.add_hook(:before_save)
    end

    it "should ran on instance when called on one" do
      MyClass.value(0)
      MyClass.after_init do 
        self.name="name"
      end
      object=MyClass.new
      object.name.should == "name"
    end

    it "should accept callbacks for any instance" do
      object=MyClass.new
      object.before_save do
        self.name="new name"
      end
      object.save
      object.name.should == "new name"
    end

    it "should detect hook by name" do
      MyClass.after_load do
        value(true)
      end
      MyClass.fire(:after_load)
      MyClass.value.should be_true
    end

    it "should have named fire method" do
      MyClass.after_load {
        MyClass.value(MyClass.value()+1)
      }
      object=MyClass.new
      MyClass.fire_after_load
      object.fire_after_load
      MyClass.value.should == 2
    end

    it "should execute callback each time" do
      MyClass.value(0)
      MyClass.after_load do
        value(value()+1)
      end
      MyClass.fire(:after_load)
      MyClass.fire(:after_load)
      MyClass.value.should == 2
    end


    context "wrap around" do

      it "should allow to wrap around when #fire receive block" do
        MyClass.after_load do
          value("first")
          yield if block_given?
          value("second")
        end

        MyClass.fire(:after_load) do
          value().should=="first"
        end
        MyClass.value.should == "second"
      end
    end
  end


  describe "named callbacks" do
    it "should add callbacks" do
      Lolita::Hooks.components.add_hook(:before)
      Lolita::Hooks.components.hooks.should have(1).hook
    end

    it "should filter by name" do
      Counter.set(0)
      Lolita::Hooks.component(:"list").before do
        Counter.set(1)
      end

      Lolita::Hooks.component(:"tab").before do
        Counter.set(2)
      end

      Lolita::Hooks.component(:"list").fire(:before) 
      Counter.get.should == 1
    end

  end
end
