require File.expand_path(File.dirname(__FILE__) + '/../../simple_spec_helper')

describe Lolita::Extensions::Authentication::Proxy do 
  let(:klass){ Lolita::Extensions::Authentication::Proxy }
  let(:proxy){ klass.new(Object.new,{}) }

  it "should create new proxy" do
    expect do
      klass.new(Object.new,{})
    end.not_to raise_error
  end

  it "should have #current_user" do
    proxy.respond_to?(:current_user).should be_truthy
  end
  
  it "should have #user_signed_in?" do
    proxy.respond_to?(:user_signed_in?).should be_truthy
  end

  it "should have #adapter" do
    proxy.adapter.is_a?(Object)
  end

  it "should have #authenticate_user!" do
    proxy.respond_to?(:authenticate_user!).should be_truthy
  end

  it "should have #sign_out_path" do
    proxy.respond_to?(:sign_out_path).should be_truthy
  end

  it "should have #sign_out_via" do
    proxy.respond_to?(:sign_out_via).should be_truthy
  end

  it "should have #edit_path" do
    proxy.respond_to?(:edit_path).should be_truthy
  end

  describe 'Connecting adapter' do
    context 'default adapter' do
      it "should create when Authentication is not specified" do
        proxy.adapter.should be_a(Lolita::Extensions::Authentication::DefaultAdapter)
      end
    end
    context 'devise adapter' do
      it "should create when Lolita.authentication is specified" do
        Lolita.authentication = :test
        proxy.adapter.should be_a(Lolita::Extensions::Authentication::DeviseAdapter)
        Lolita.authentication = nil
      end
    end
  end
end
