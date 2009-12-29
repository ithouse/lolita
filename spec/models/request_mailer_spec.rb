require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

class RequestObject < Struct.new(:host_with_port,:remote_ip,:url,:request_method, :env)
  def xml_http_request?
    true
  end
end

describe RequestMailer do
  it "should deliver bug" do
    request = RequestObject.new(
      "localhost:3000",
      "127.0.0.1",
      "/hello/",
      "POST",
      {:HTTP_USER_AGENT => "BOT", :HTTP_REFERER => "underground"}
    )
    
    RequestMailer.deliver_bug(
      :msg => "BIG BUG",
      :title => "Bug in system",
      :request => request,
      :params => {:a => 33, :c => 55, :zzzz => {:none => "none"}},
      :session => {:current_user => Admin::SystemUser.new, :tools => 33, :beta => "gamma"}
    )
  end
end

