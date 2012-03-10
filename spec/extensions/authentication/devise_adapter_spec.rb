require File.expand_path(File.dirname(__FILE__) + '/../../simple_spec_helper')

module ActionController
  class Base

    def current_user
      "user_1"
    end

    def authentitcate_test_user!
      true 
    end

    def edit_admin_password_path
      "/edit_admin"
    end
    
    def destroy_admin_session_path
      "/destroy_admin"
    end

    def current_admin
      "admin_1"
    end
  end
end

module Devise
  def self.sign_out_via
    "get"
  end
end

describe Lolita::Extensions::Authentication::DeviseAdapter do
  around(:each){ |example|
    Lolita.authentication = :authentitcate_test_user! 
    Lolita.user_classes = ["Admin","User"]
    example.run
    Lolita.authentication = nil
    Lolita.user_classes = []
  }
  let(:klass){ Lolita::Extensions::Authentication::DeviseAdapter }
  let(:controller){ActionController::Base.new}
  let(:adapter){ klass.new(controller,{}) }

  it "should create new DeviseAdapter" do
    expect do
      klass.new(ActionController::Base,{})
    end.not_to raise_error
  end

  it "should not have current user" do
    Lolita.user_classes = ["User"]
    adapter.current_user.should == controller.current_user
  end

  it "should not be signed in" do
    adapter.user_signed_in?.should be_true
  end

  it "should authenticate user" do
    adapter.authenticate_user!.should be_true
  end

  it "should have sign_out_via method" do
    adapter.sign_out_via.should == "get"
  end

  it "should have edit path" do
    adapter.edit_path.should == "/edit_admin"
  end

  it "should have sign out path" do 
    adapter.sign_out_path.should == "/destroy_admin"
  end


  describe 'Integration with proxy' do
    let(:proxy){ Lolita::Extensions::Authentication::Proxy.new(controller,{}) }
      it "should have the same method results for adapter and proxy" do
        proxy.adapter = adapter
        %w(current_user user_signed_in? authenticate_user!).each do |name|
          proxy.send(name).should eql(adapter.send(name))
        end
      end
  end
end