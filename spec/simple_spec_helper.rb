require_relative '../lib/lolita'
require 'rubygems'
require 'bundler/setup'
unless ENV['CI']
  require 'pry-byebug'
end
