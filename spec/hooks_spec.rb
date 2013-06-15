require 'simple_spec_helper'


class MyClass
  def self.value(value=nil)
    @value=value if value
    @value
  end

  attr_accessor :name
  def initialize
    self.run(:after_init)
  end

  def save
    self.run(:before_save)
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
      MyClass.run(:after_load)
      MyClass.value.should be_true
    end

    it "should have named run method" do
      MyClass.after_load {
        MyClass.value(MyClass.value()+1)
      }
      object=MyClass.new
      MyClass.run_after_load
      object.run_after_load
      MyClass.value.should == 2
    end

    it "should execute callback each time" do
      MyClass.value(0)
      MyClass.after_load do
        value(value()+1)
      end
      MyClass.run(:after_load)
      MyClass.run(:after_load)
      MyClass.value.should == 2
    end


    describe "block content" do
      it "should return block content" do
        MyClass.after_load do
          "My name"+
          let_content.to_s
        end

        output=MyClass.run(:after_load) do
          " is Earl"
        end

        output.should == "My name is Earl"
      end
    end

    context "wrap around" do

      it "should allow to wrap around when #run receive block" do
        MyClass.after_load do
          value("first")
          let_content()
        end

        MyClass.run(:after_load) do
          value("second")
        end
        MyClass.value.should == "second"
      end

      it "should call default block when no block passed as callback" do
        MyClass.run(:after_load) do
          value("inblock")
        end

        MyClass.value.should=="inblock"
      end
    end

    context "methods as callbacks" do
      class MethodTestClass
        include Lolita::Hooks
        add_hook :before_save
        before_save :set_name

        def save
          self.run_before_save
        end

        private

        def self.set_name
          @name="Class name"
        end

        def set_name
          @name="Name"
        end
      end

      it "should call callback for method on class" do
        MethodTestClass.run_before_save
        MethodTestClass.instance_variable_get(:"@name").should == "Class name"
      end

      it "should run callbac on instance" do
        object=MethodTestClass.new
        object.save
        object.instance_variable_get(:"@name").should == "Name"
      end
    end
  end


  describe "named callbacks" do
    before(:each) do
       Lolita::Hooks::NamedHook.add(:bazingas) unless Lolita::Hooks::NamedHook.exist?(:bazinga)
    end

    after(:each) do
      Lolita::Hooks.bazingas.clear_hooks
    end

    it "should add callbacks" do
      Lolita::Hooks.bazingas.add_hook(:before)
      Lolita::Hooks.bazingas.hooks.should have(1).hook
    end

    it "should filter by name" do
      Lolita::Hooks.bazingas.add_hook(:before)
      Counter.set(0)
      Lolita::Hooks.bazinga(:"list").before do
        Counter.set(Counter.get+1)
      end

      Lolita::Hooks.bazinga(:"tab").before do
        Counter.set(Counter.get+1)
      end

      Lolita::Hooks.bazinga(:"list").run(:before)
      Counter.get.should == 1
    end

    it "should run on each named object when defined for all collection" do
      Lolita::Hooks.bazingas.add_hook(:after)
      Counter.set(0)
      Lolita::Hooks.bazingas.after do
        Counter.set(Counter.get+1)
      end
      Lolita::Hooks.bazinga(:"list").run(:after)
      Lolita::Hooks.bazinga(:"tab").run(:after)
      Counter.get.should == 2
    end

    it "should execute run block when no callback block given" do
      Lolita::Hooks.bazingas.add_hook(:around)
      Counter.set(0)
      Lolita::Hooks.bazingas.run(:around) do
        Counter.set(1)
      end
      Counter.get.should==1
    end

    it "should run all named hook callbacks when runned on named collection" do
      pending "Need to update functionality to work."
      Lolita::Hooks.bazingas.add_hook(:after)
      Counter.set(0)
      Lolita::Hooks.bazinga(:"list").after do
        Counter.set(Counter.get+1)
      end
      Lolita::Hooks.bazinga(:"tab").after do
        Counter.set(Counter.get+1)
      end
      Lolita::Hooks.bazingas.run(:after)
      Counter.get.should == 2
    end

  end
end