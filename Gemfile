source 'http://rubygems.org'

gem 'rails', '~>3.2.0'
gem 'kaminari', '~>0.13.0'
gem 'abstract', "~>1"

gem 'builder', '~> 3.0' 

gem 'haml', '~> 3.1.2'
gem 'jquery-rails'
gem 'tinymce-rails','~>3.4.8', :require => 'tinymce-rails'

group :mongoid do
	gem 'mongo', '~> 1.4.0'
	gem 'mongoid', '~> 2.3.0'
	gem 'bson_ext', '~> 1.4.0'
end

group :assets do
 	gem 'sass-rails',   '~> 3.2.0'
  gem 'coffee-rails', '~> 3.2.0'
  gem 'uglifier'
end

gem 'jeweler', '~> 1.8.3', :group=>:development

group :test,:development do
	gem 'linecache19', :git => 'git://github.com/mark-moseley/linecache'
  gem 'ruby-debug-base19x', '~> 0.11.30.pre4'
  gem 'ruby-debug19'

  gem 'fabrication', "~>1.3.2"
	gem 'rspec', '~>2.9.0'
	gem 'rspec-rails','~>2.9.0'
	gem 'capybara', '~>1.1.2'
  gem 'capybara-webkit', '~>0.11.0'
	gem 'ffaker', "~>1"
end
