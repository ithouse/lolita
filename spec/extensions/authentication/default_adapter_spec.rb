require File.expand_path(File.dirname(__FILE__) + '/../../simple_spec_helper')

describe Lolita::Extensions::Authentication::DefaultAdapter do
  let(:klass){ Lolita::Extensions::Authentication::DefaultAdapter }
  let(:adapter){ klass.new(Object.new,{}) }

  it "should createnew DefaultAdapter" do
    expect do
      klass.new(Object.new,{})
    end.not_to raise_error
  end

  it "should not have current user" do
    adapter.current_user.should be_nil
  end

  it "should not be signed in" do
    adapter.user_signed_in?.should be_false
  end

  it "should authenticate user" do
    adapter.authenticate_user!.should be_true
  end

  describe 'Integration with proxy' do
    let(:proxy){ Lolita::Extensions::Authentication::Proxy.new(Object.new,{}) }
      it "should have the same method results for adapter and proxy" do
        proxy.adapter = adapter
        %w(current_user user_signed_in? authenticate_user!).each do |name|
          proxy.send(name).should eql(adapter.send(name))
        end
      end
  end
end