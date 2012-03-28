
require 'rubygems'
require "bundler/setup"
require 'benchmark'
require 'coverage_helper'
#require 'ruby-debug'
Benchmark.bm do |x|
  x.report("Loading ORM: ") do
    LOLITA_ORM=:mongoid
    require "orm/#{LOLITA_ORM}"
  end
  x.report("Loading rails: ") do
    require "rails"
    require "rails_app/config/environment"
  end
  x.report("Loading test stuff: ") do
    require 'rspec/rails'
    require 'ffaker'
  end
  x.report("Loading factories") do
    Dir["#{File.dirname(__FILE__)}/fabricators/**/*_fabricator.rb"].each {|f| require f}
  end
  RSpec.configure do |config|
    config.mock_with :rspec

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
