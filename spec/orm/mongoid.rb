Bundler.setup(:mongoid)
require 'mongoid'

Mongoid.configure do |config|
  config.master = Mongo::Connection.new('127.0.0.1', 27017).db("lolita3-test")
end

# truncate data
Mongoid.database.collections.each do |collection|
  unless collection.name =~ /^system\./
    collection.remove
  end
end