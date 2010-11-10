#Dir[File.expand_path(File.join(File.dirname(__FILE__),'..','lib','**','*.rb'))].each {|f| require f}
Dir[File.expand_path(File.join(File.dirname(__FILE__),'..','lib','**','*.rb'))].each {|f| require f}
require 'mongoid'

Mongoid.configure do |config|
  name = "lolita2_test_development"
  host = "localhost"
  config.master = Mongo::Connection.new.db(name)
  config.slaves = [
    Mongo::Connection.new(host, 27017, :slave_ok => true).db(name)
  ]
  #config.use_object_ids = true
  config.persist_in_safe_mode = false
end

class TestClass1
  include Mongoid::Document
  include Lolita::Configuration
  field :field_one
  lolita
end

class TestClass2
  include Mongoid::Document
  include Lolita::Configuration
  field :field_one
  lolita do
    
  end
end