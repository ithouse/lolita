source 'http://rubygems.org'

gemspec

group :test, :development do 
  gem "debugger"
  gem "fabrication", "~> 1.3.2"
  gem "rspec", "~> 2"
  gem "capybara", "~> 1"
  gem "capybara-webkit", ">= 0"
  gem "ffaker", "~> 1"
end

gem "simplecov", :require => false, :group => :test

group :rails do 
  gem "rails" , "~> 3.2.0"
  gem "rspec-rails", "~> 2.9.0"
  gem "jquery-rails"
  gem "tinymce-rails-config-manager"
end
  
group :mongoid do
	gem 'mongo', '~> 1.4.0'
	gem 'mongoid', '~> 2.3.0'
	gem 'bson_ext', '~> 1.4.0'
end
