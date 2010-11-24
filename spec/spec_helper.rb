require 'rubygems'
require 'rspec'
require 'ruby-debug' 
require File.expand_path(File.join(File.dirname(__FILE__),'..','lib','lolita.rb'))
#Dir[)].each {|f| require f}

ADAPTER='mongoid'
require 'adapter_helper'

def create_recs
  f=Post.create(:field_one=>"one")
  s=Post.create(:field_one=>"two")
  @recs=[f,s]
end