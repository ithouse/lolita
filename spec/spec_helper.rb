require 'rubygems'
require 'rspec'
require File.expand_path(File.join(File.dirname(__FILE__),'..','lib','lolita.rb'))
#Dir[)].each {|f| require f}

ADAPTER='ar'
require 'adapter_helper'

def create_recs
  f=TestClass1.create(:field_one=>"one")
  s=TestClass1.create(:field_one=>"two")
  @recs=[f,s]
end