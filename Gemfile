source 'http://rubygems.org'
source 'https://gems.gemfury.com/8n1rdTK8pezvcsyVmmgJ/' 

# Thing how to seperate gems for Rails Engine from those that are only for lolita
gem 'rails', '~>3.2.0'
gem 'kaminari', '~>0.13.0'
gem 'abstract'

gem 'builder', '~> 3.0' 

gem 'haml', '~> 3.1.2'
gem 'jquery-rails'
gem 'tinymce-rails','~>3.4.8' :require => 'tinymce-rails'

group :mongoid do
	gem 'mongo', '~> 1.4.0'
	gem 'mongoid', '~> 2.3.0'
	gem 'bson_ext', '~> 1.4.0'
end

#gem 'cover_me', '>= 1.0.0.rc6', :group => :test
group :assets do
 	gem 'sass-rails',   '~> 3.2.0'
  gem 'coffee-rails', '~> 3.2.0'
  gem 'uglifier'
end

gem 'jeweler', '~> 1.6.4', :group=>:development

group :test,:development do
	# gem 'linecache19',       '>= 0.5.13'
	# gem 'ruby-debug-base19', '>= 0.11.26'
 #  gem 'ruby-debug19'
	gem 'rspec', '~>2.8.0'
	gem 'rspec-rails','~>2.8.0'
	gem 'factory_girl'
	gem 'ffaker'
	gem 'database_cleaner'
end
