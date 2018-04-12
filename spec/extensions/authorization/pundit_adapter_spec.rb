require File.expand_path(File.dirname(__FILE__) + '/../../simple_spec_helper')

class TestApplicationController
  include Lolita::Extensions
end

class TestPolicy
  def initialize user, record
  end

  def read?
    true
  end

  def create?
    false
  end
end

module Pundit
  class NotAuthorizedError < StandardError ; end

  def self.policy user, record
  end
end

describe Lolita::Extensions::Authorization::PunditAdapter do
  let(:klass){ Lolita::Extensions::Authorization::PunditAdapter }
  around(:each){|example|
    Lolita.authorization = 'Pundit'
    Lolita.policy_class = TestPolicy
    example.run
    Lolita.authorization = nil
    Lolita.policy_class = nil
  }
  let(:adapter){ klass.new(TestApplicationController.new,{request: double(env: {})}) }

  it "should create new" do
    expect do
      klass.new(TestApplicationController.new,{request: double(env: {})})
    end.not_to raise_error
  end

  it "should raise error without authorization" do
    expect do
      Lolita.authorization = nil
      klass.new(TestApplicationController.new,{request: double(env: {})})
    end.to raise_error(Lolita::NoAuthorizationDefinedError)
  end

  context "current user" do

    before do
      TestApplicationController.any_instance.stub(authentication_proxy: double(current_user: double('Admin')))
    end

    it "can do some action with current policy" do
      adapter.can?(:read,"HiddenText".class).should be_truthy
      adapter.can?(:create,"HiddenText".class).should be_falsey
    end

    it "can ONLY do actions from policy" do
      adapter.cannot?(:read,"HiddenText".class).should be_falsey
      adapter.cannot?(:create,"HiddenText".class).should be_truthy
    end

    it "should have current policy" do
      adapter.current_ability(Object.new).should be_a(Lolita.policy_class)
    end

    it "should not authorize resource without current_user" do
      adapter2 = klass.new(nil)
      expect do
        adapter2.authorize!(:read, Object)
      end.to raise_error
    end

    it "should authorize resource" do
      expect do
        adapter.authorize!(:read, Object).should be_truthy
      end.to_not raise_error
    end
  end

  describe 'Integration with proxy' do
    let(:proxy){
      mock_class = Object.new
      mock_class.class_eval{include Lolita::Extensions}
      Lolita::Extensions::Authorization::Proxy.new(mock_class,{request: double(env: {})})
    }

    before do
      TestApplicationController.any_instance.stub(authentication_proxy: double(current_user: double('Admin')))
    end

    it "should have the same method results for adapter and proxy" do
      proxy.adapter = adapter
      %w(can? cannot? authorize!).each do |name|
        proxy.send(name,:read, String).should eql(adapter.send(name,:read,String))
      end
      proxy.adapter.current_ability(Object) == adapter.current_ability(Object)
    end
  end
end
