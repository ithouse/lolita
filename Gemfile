source "http://rubygems.org"

# Thing how to seperate gems for Rails Enginge from those that are only for lolita
gem "rails", "~>3.0"
gem "will_paginate", "~> 3.0.pre2"
gem "abstract"

group :mongoid do
  gem "mongo"
  gem "mongoid", "~> 2.0.0.rc.7"
  gem "bson_ext"
end

#gem 'cover_me', '>= 1.0.0.rc6', :group => :test
group :test,:development do
  gem "rspec", ">=2.2.0"
  gem "rspec-rails"
  gem "factory_girl"
  gem 'ffaker' 
 # gem "rspec-cells"
  #gem "sqlite3-ruby"
  gem "ruby-debug19"
end
