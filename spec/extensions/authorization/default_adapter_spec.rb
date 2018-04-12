require File.expand_path(File.dirname(__FILE__) + '/../../simple_spec_helper')

describe Lolita::Extensions::Authorization::DefaultAdapter do
  let(:klass){ Lolita::Extensions::Authorization::DefaultAdapter }
  let(:adapter){ klass.new(Object.new,{}) }

  it "should create new" do
    expect do
      klass.new(Object.new,{})
    end.not_to raise_error
  end
  
  context "current user" do

    it "can do all" do
      adapter.can?(:read,Object.new).should be_truthy
    end

    it "cannot do nothing" do
      adapter.cannot?([]).should be_falsey
    end

    it "should not have current ability" do
      adapter.current_ability.should be_nil
    end
    
    it "should be authorized for all" do
      expect do
        adapter.authorize!
      end.not_to raise_error
    end
  end

  describe 'Integration with proxy' do
    let(:proxy){ Lolita::Extensions::Authorization::Proxy.new(Object.new,{}) }
      it "should have the same method results for adapter and proxy" do
        proxy.adapter = adapter
        %w(can? cannot? current_ability authorize!).each do |name|
          proxy.send(name).should eql(adapter.send(name))
        end
      end
  end
end
