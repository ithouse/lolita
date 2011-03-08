#require 'cover_me'
#CoverMe.config do |c|
#  # where is your project's root:
#  c.project.root="c:/a_work/ruby_docs/lolita3" # => "Rails.root" (default)
#
#  # what files are you interested in coverage for:
#  #c.file_pattern # => /(#{CoverMe.config.project.root}\/app\/.+\.rb|#{CoverMe.config.project.root}\/lib\/.+\.rb)/i (default)
#
#  # where do you want the HTML generated:
#  c.html_formatter.output_path # => File.join(CoverMe.config.project.root, 'coverage') (default)
#
#  # what do you want to happen when it finishes:
#  c.at_exit # => Proc.new {
#  if CoverMe.config.formatter == CoverMe::HtmlFormatter
#    index = File.join(CoverMe.config.html_formatter.output_path, 'index.html')
#    if File.exists?(index)
#      `open #{index}`
#    end
#  end
#
#end

require 'rubygems'
#require 'ruby-debug'
LOLITA_ORM=:mongoid
require "orm/#{LOLITA_ORM}"

require "rails_app/config/environment"

require 'rspec/rails'
require 'ffaker'
require 'factory_girl'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}
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
#CoverMe.complete!
#require 'simplecov'
#SimpleCov.start 'rails'