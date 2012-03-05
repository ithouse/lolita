require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "lolita"
  gem.homepage = "http://github.com/ithouse/lolita"
  gem.license = "MIT"
  gem.summary = %Q{Great Rails CMS.}
  gem.description = %Q{Great Rails CMS, that turns your business logic into good-looking, fully functional workspace. }
  gem.email = "support@ithouse.lv"
  gem.authors = ["ITHouse (Latvia) and Arturs Meisters"]
  # Include your dependencies below. Runtime dependencies are required when using your gem,
  # and development dependencies are only needed for development (ie running rake tasks, tests, etc)
  #  gem.add_runtime_dependency 'jabber4r', '> 0.1'
  #  gem.add_development_dependency 'rspec', '> 1.2.3'
end
Jeweler::RubygemsDotOrgTasks.new


task :default => :test

# require 'rake/rdoctask'
# Rake::RDocTask.new do |rdoc|
#   version = File.exist?('VERSION') ? File.read('VERSION') : ""

#   rdoc.rdoc_dir = 'rdoc'
#   rdoc.title = "lolita #{version}"
#   rdoc.rdoc_files.include('README*')
#   rdoc.rdoc_files.include('lib/**/*.rb')
# end

# require 'metric_fu'
# MetricFu::Configuration.run do |config|
#   config.rcov[:test_files] = ['spec/**/*_spec.rb']  
#   config.rcov[:rcov_opts] << "-Ispec" # Needed to find spec_helper
#   config.metrics -= [:flog]
# end