source "http://rubygems.org"

# Thing how to seperate gems for Rails Engine from those that are only for lolita
gem "rails", "~>3.1.1"
gem "kaminari", "~>0.12.4"
gem "abstract"

gem "builder", "~> 3.0" 

gem "haml", "~> 3.1.2"
gem 'jquery-rails'
gem 'tinymce-rails', :require => 'tinymce-rails'

group :mongoid do
	gem "mongo", "~> 1.4.0"
	gem "mongoid", "~> 2.3.0"
	gem "bson_ext", "~> 1.4.0"
end

#gem 'cover_me', '>= 1.0.0.rc6', :group => :test
group :assets do
 	gem 'sass-rails',   "~> 3.1.4"
  gem 'coffee-rails', "~> 3.1.1"
  gem 'uglifier'
end

gem "jeweler", "~> 1.6.4", :group=>:development

group :test,:development do
	gem 'linecache19', :git => 'git://github.com/mark-moseley/linecache'
  gem 'ruby-debug-base19x', '~> 0.11.30.pre4'
  gem 'ruby-debug19'
	gem "metric_fu"
	gem "fattr"
	gem "arrayfields"
	gem "map"
	gem "rspec", "~>2.7.0"
	gem "rspec-rails","~>2.7.0"
	gem "factory_girl"
	gem 'ffaker'
	gem "database_cleaner"
end
