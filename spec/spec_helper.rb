require 'rubygems'
require 'bundler/setup'
require 'byebug'
# require 'simplecov'
# SimpleCov.start do

#end
ENV["lolita-env"] = "rails"

#Bundler.setup(:default,:rails,:test,:development)
require 'benchmark'
Benchmark.bm do |x|
  x.report("Loading ORM: ") do
    LOLITA_ORM=:mongoid
    require "orm/#{LOLITA_ORM}"
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

  x.report("Loading test stuff: ") do
    require 'ffaker'
  end
  x.report("Loading factories") do
    Dir["#{File.dirname(__FILE__)}/fabricators/**/*_fabricator.rb"].each {|f| require f}
  end
  RSpec.configure do |config|
    config.mock_with :rspec
    config.order = 'rand:3455'
    if LOLITA_ORM==:active_record
      #config.fixture_path = "#{::Rails.root}/spec/fixtures"
      config.use_transactional_fixtures = true
    elsif LOLITA_ORM==:mongoid
      config.after(:each) do 
        Mongoid.database.collections.each do |collection|
          unless collection.name =~ /^system\./
            collection.remove
          end
        end
      end
    end
  end
end
