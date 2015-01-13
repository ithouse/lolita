require 'rubygems'
require 'bundler/setup'
unless ENV['CI']
  require 'pry-byebug'
end
# require 'simplecov'
# SimpleCov.start do

#end
ENV["lolita-env"] = "rails"

#Bundler.setup(:default,:rails,:test,:development)
require 'benchmark'
Benchmark.bm do |x|
  x.report("Loading ORM: ") do
    LOLITA_ORM = ENV["LOLITA_ORM"] || :active_record
    require "orm/#{LOLITA_ORM}"
  end
  if LOLITA_ORM == 'mongoid'
    require 'kaminari'
    Kaminari::Hooks.init
  end
  if ENV["lolita-env"] == "rails"
    x.report("Loading rails: ") do
      require 'rails'
      require 'lolita'
      Lolita.load!
      require 'rails_app/config/environment'
      require 'rspec/rails'
    end
  end

  #x.report("Loading test stuff: ") do
    require 'ffaker'
  #end
  #x.report("Loading factories") do
    Dir["#{File.dirname(__FILE__)}/fabricators/**/*_fabricator.rb"].each {|f| require f}
  #end
  Dir["#{File.dirname(__FILE__)}/support/**/*[^_spec].rb"].each {|f| require f}
  RSpec.configure do |config|
    config.mock_with :rspec
    config.order = "rand:3455"
    config.infer_spec_type_from_file_location!
  end
end
