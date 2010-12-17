require 'rubygems'
require 'ruby-debug'
LOLITA_ORM=:mongoid
require "rails_app/config/environment"
require 'rspec/rails'
require "orm/#{LOLITA_ORM}"

Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}
RSpec.configure do |config|
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  if LOLITA_ORM==:active_record
    #config.fixture_path = "#{::Rails.root}/spec/fixtures"
    config.use_transactional_fixtures = true
  end
end

