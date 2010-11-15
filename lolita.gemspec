# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "lolita/version"

Gem::Specification.new do |s|
  s.name        = "lolita"
  s.version     = Lolita::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["ITHouse","Artūrs Meisters"]
  s.email       = ["arturs@ithouse.lv"]
  s.homepage    = "http://rubygems.org/gems/lolita"
  s.summary     = %q{CMS for developers}
  s.description = %q{CMS for developers}

  s.required_rubygems_version = ">=1.3.6"
  s.rubyforge_project = "lolita"

  s.add_development_dependency "bundler", ">=1.0.2"
  s.add_development_dependency "rspec", ">=2.0.1"
  s.add_development_dependency "mongoid", ">=2.0.0"
  s.add_development_dependency "sqlite3-ruby", ">=1.3.2"

  s.add_dependency "absctract", ">=1.0.0"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
