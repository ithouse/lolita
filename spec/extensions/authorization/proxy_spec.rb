require File.expand_path(File.dirname(__FILE__) + '/../../simple_spec_helper')

describe Lolita::Extensions::Authorization::Proxy do 
  let(:klass){ Lolita::Extensions::Authorization::Proxy }
  let(:proxy){ klass.new(Object.new,{}) }
  
  it "should create new proxy" do
    expect do
      klass.new(Object.new,{})
    end.not_to raise_error
  end

  it "should have #can?" do
    proxy.respond_to?(:can?).should be_true
  end
  
  it "should have #cannot?" do
    proxy.respond_to?(:cannot?).should be_true
  end

  it "should have #authorize!" do
    proxy.respond_to?(:authorize!).should be_true
  end

  it "should have #current_ability" do
    proxy.respond_to?(:current_ability).should be_true
  end

  describe 'Connecting adapter' do
    context 'default adapter' do
      it "should create when authorization is not specified or is 'Default'" do
        proxy.adapter.should be_a(Lolita::Extensions::Authorization::DefaultAdapter)
        Lolita.authorization = 'Default'
        proxy.adapter.should be_a(Lolita::Extensions::Authorization::DefaultAdapter)
      end
    end
    context 'devise adapter' do
      let(:proxy){ 
        mock_class = Object.new
        mock_class.class_eval{include Lolita::Extensions}
        klass.new(mock_class,{}) 
      }
      it "should create when Lolita.authentication is specified" do
        Lolita.authorization = 'CanCan'
        proxy.adapter.should be_a(Lolita::Extensions::Authorization::CanCanAdapter)
      end
    end
  end
end