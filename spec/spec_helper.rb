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
require "bundler/setup"
require 'benchmark'
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
