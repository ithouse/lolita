source "http://rubygems.org"

gemspec

group :test, :development do
  unless ENV['CI']
    gem 'pry-byebug'
  end
  gem "fabrication", "~> 2.9.3"
  gem "rspec", "~> 2.14"
  gem "capybara", "~> 2"
  gem "ffaker", "~> 1"
  gem "generator_spec", "~> 0.9.0"
  gem "sqlite3"
  gem "database_cleaner"
end

gem "simplecov", require: false, group: :test

group :rails do
  gem "rails" , "~> 4.0.0"
  gem "rspec-rails", "~> 2.14"
  gem "coffee-rails", "~> 4.0.1"
  gem "therubyracer", "~> 0.12.0"
end

group :mongoid do
  gem "bson_ext"
  gem "mongoid", "~> 4.0.0.alpha1"
end
