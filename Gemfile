source "http://rubygems.org"

# Thing how to seperate gems for Rails Engine from those that are only for lolita
gem "rails", "~>3.1.0"
gem "kaminari", "~>0.12.4"
gem "abstract"
gem "builder", "~> 3.0" 
gem "haml", "~> 3.1.2"
gem 'jquery-rails'

group :mongoid do
	gem "mongo", "~> 1.3.0"
	gem "mongoid", "~> 2.1.7"
	gem "bson_ext", "~> 1.3.0"
end

#gem 'cover_me', '>= 1.0.0.rc6', :group => :test
gem "jeweler", "~> 1.5.2", :group=>:development
group :test,:development do
	gem "metric_fu", "2.0.1"
	gem "rspec", "~>2.6.0"
	gem "rspec-rails","~>2.6.0"
	gem "factory_girl"
	gem 'ffaker'
	gem "ruby-debug19"
	gem "cucumber-rails"
	gem "capybara"
	gem "database_cleaner"
	gem "akephalos"
end