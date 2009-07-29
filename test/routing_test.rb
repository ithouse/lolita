require "#{File.dirname(__FILE__)}/test_helper"

class RoutingTest < Test::Unit::TestCase
  def setup
    ActionController::Routing::Routes.draw do |map|
      map.bundle :lolita
    end
  end

  def test_lolitas_route
    assert_recognition :get, "/system/login", :controller => "admin/user", :action => "login"
  end

  private

  def assert_recognition(method, path, options)
    result = ActionController::Routing::Routes.recognize_path(path, :method => method)
    assert_equal options, result
  end
end