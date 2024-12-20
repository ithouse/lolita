source 'http://rubygems.org'

gemspec

group :test, :development do
  unless ENV['CI']
    gem 'pry-byebug'
  end
  gem 'fabrication', '~> 2.9.3'
  gem 'rspec-core', '~> 3.7.1'
  gem 'rspec-its'
  gem 'rspec-collection_matchers'
  gem 'capybara', '~> 2'
  gem 'ffaker', '~> 1'
  gem 'generator_spec', '~> 0.9.0'
  gem 'sqlite3'
  gem 'database_cleaner', '~> 1.6.2'
  gem 'rails-controller-testing'
end

gem 'simplecov', require: false, group: :test

group :rails do
  gem "rails" , "~> 5.2.0"
  gem "rspec-rails", "~> 3.7.2"
  gem "coffee-rails", "~> 4.2.2"
  gem "therubyracer", "~> 0.12.0"
  gem "erubis"
end

group :mongoid do
  gem 'bson_ext'
  gem 'kaminari', '~> 1.2'
  gem 'mongoid', '~> 6.0.0'
end
