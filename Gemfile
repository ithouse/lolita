source 'http://rubygems.org'

gemspec

group :test, :development do
  gem "debugger"
  gem "fabrication", "~> 1.3.2"
  gem "rspec", "~> 2.13"
  gem "capybara", "~> 2"
  gem "capybara-webkit", ">= 0.14.2"
  gem "ffaker", "~> 1"
end

gem "simplecov", :require => false, :group => :test

group :rails do
  gem "rails" , "~> 3.2.0"
  gem "rspec-rails", "~> 2.13"
  gem "jquery-rails"
  gem "coffee-rails"
  gem "therubyracer"
  gem "tinymce-rails-config-manager"
end

group :mongoid do
	gem 'mongo', '~> 1.9.0'
	gem 'mongoid', '~> 2.7.1'
	gem 'bson_ext', '~> 1.9.0'
end
