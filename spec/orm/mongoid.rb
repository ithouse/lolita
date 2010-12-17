require 'mongoid'

Mongoid.configure do |config|
  config.master = Mongo::Connection.new('127.0.0.1', 27017).db("lolita3-test")
end

class ActiveSupport::TestCase
  setup do
    Post.delete_all
    Comment.delete_all
    Address.delete_all
    Preference.delete_all
    Profile.delete_all
  end
end