require 'rake'
require 'rspec/core/rake_task'
require 'bundler'

RSpec::Core::RakeTask.new(:rspec)
Bundler::GemHelper.install_tasks

task :default => :rspec
