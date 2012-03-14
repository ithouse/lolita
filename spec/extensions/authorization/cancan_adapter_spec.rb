require File.expand_path(File.dirname(__FILE__) + '/../../simple_spec_helper')

class TestApplicationController
  include Lolita::Extensions

  def authorize! *args
    "context_response"
  end
end

class TestAbility
  def initialize *args
  end

  def can? action,klass
    action == :read && klass == String
  end

  def cannot? *args
    !can?(*args)
  end

  def authorize! *args
    "ability_response"
  end
end

module CanCan
end

describe Lolita::Extensions::Authorization::CanCanAdapter do
  let(:klass){ Lolita::Extensions::Authorization::CanCanAdapter }
  around(:each){|example|
    Lolita.authorization = 'CanCan'
    Lolita.ability_class = TestAbility
    example.run
    Lolita.authorization = nil
    Lolita.ability_class = nil
  }
  let(:adapter){ klass.new(TestApplicationController.new,{}) }

  it "should create new" do
    expect do
      klass.new(TestApplicationController.new,{})
    end.not_to raise_error
  end

  it "should raise error without authorization" do
    expect do
      Lolita.authorization = nil
      klass.new(TestApplicationController.new,{})
    end.to raise_error(Lolita::NoAuthorizationDefinedError)
  end

  context "current user" do

    it "can do some action with current abilities" do
      adapter.can?(:read,"HiddenText".class).should be_true
      adapter.can?(:create,"HiddenText".class).should be_false
    end

    it "can ONLY ado ctions from abilities" do
      adapter.cannot?(:read,"HiddenText".class).should be_false
      adapter.cannot?(:create,"HiddenText".class).should be_true
    end

    it "should have current ability" do
      adapter.current_ability.should be_a(Lolita.ability_class)
    end
    
    it "should authorize resource" do
      adapter2 = klass.new(nil)
      expect do
        adapter2.authorize!(:read,Object).should == "ability_response"
        adapter.authorize!(:read,Object).should == "context_response"
      end.not_to raise_error
    end
  end

  describe 'Integration with proxy' do
    let(:proxy){ 
      mock_class = Object.new
      mock_class.class_eval{include Lolita::Extensions}
      Lolita::Extensions::Authorization::Proxy.new(mock_class,{}) 
    }
    it "should have the same method results for adapter and proxy" do
      proxy.adapter = adapter
      %w(can? cannot? authorize!).each do |name|
        proxy.send(name,:read,String).should eql(adapter.send(name,:read,String))
      end
      proxy.adapter.current_ability == adapter.current_ability
    end
  end
end