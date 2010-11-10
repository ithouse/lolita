$:<<File.dirname(__FILE__) unless $:.include?(File.dirname(__FILE__))
require 'mongoid'
require "configuration/base"
#require 'bson_ext'
#puts Mongo::Connection.class_variable_get(:@@current_request_id)
#Mongoid.configure do |config|
#  name = "lolita2_test_development"
#  host = "localhost"
#  config.master = Mongo::Connection.new.db(name)
#  config.slaves = [
#    Mongo::Connection.new(host, 27017, :slave_ok => true).db(name)
#  ]
#  #config.use_object_ids = true
#  config.persist_in_safe_mode = false
#end
#puts Mongo::Connection.class_variable_get(:@@current_request_id)
if defined?(ActiveRecord::Base)
  ActiveRecord::Base.class_eval do
    include Lolita::Configuration
  end
else
#  .class_eval do
#    include Lolita::Configuration
#  end
#TODO varbūt šeit var pielikt pie kādas klases 
end