require 'rubygems'
require 'bundler'
require 'rspec/core/rake_task'

Bundler::GemHelper.install_tasks
RSpec::Core::RakeTask.new(:spec)

task :default do
  puts "ORM: ActiveRecord"
  ENV["LOLITA_ORM"] = "active_record"
  Rake::Task[:spec].execute
  Rake::Task[:spec].reenable

  puts "ORM: Mongoid"
  ENV["LOLITA_ORM"] = "mongoid"
  Rake::Task[:spec].execute
end
