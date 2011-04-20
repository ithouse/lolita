source "http://rubygems.org"

# Thing how to seperate gems for Rails Engine from those that are only for lolita
gem "rails", "~>3.0"
gem "kaminari", "~>0.11.0"
gem "abstract"
gem "builder", "~> 2.1.2" #cucumber asks for builder 3 but rails supports 2.1

group :mongoid do
	gem "mongo", "~> 1.3.0"
	gem "mongoid", "~> 2.0.0"
	gem "bson_ext", "~> 1.3.0"
end

#gem 'cover_me', '>= 1.0.0.rc6', :group => :test
gem "jeweler", "~> 1.5.2", :group=>:development
group :test,:development do
	gem "rspec", ">=2.2.0"
	gem "rspec-rails"
	gem "factory_girl"
	gem 'ffaker'
	# gem "rspec-cells"
	#gem "sqlite3-ruby"
	gem "ruby-debug19"
	gem "cucumber-rails"
	gem "capybara"
	gem "database_cleaner"
	gem "akephalos"
end