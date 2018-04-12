require_relative '../lib/lolita'
require 'rubygems'
require 'bundler/setup'
require 'rspec/its'
unless ENV['CI']
  require 'pry-byebug'
end
