require "bundler"
require "bundler/setup"
require 'sinatra/base'
require 'mongoid'
require 'lolita'

class SinatraTestApp < Sinatra::Base
  configure do
    Mongoid.configure do |config|
      config.master = Mongo::Connection.new('127.0.0.1', 27017).db("lolita3-test")
    end
    require './sinatra-test-models'
  end
  include Lolita::Sinatra
  lolita_for :posts
  use Lolita::RestController
  
end

SinatraTestApp.run!




