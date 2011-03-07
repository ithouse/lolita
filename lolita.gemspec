# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "lolita/version"

Gem::Specification.new do |s|
  s.name        = "lolita"
  s.version     = Lolita::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["ITHouse","Artūrs Meisters"]
  s.email       = ["support@ithouse.lv"]
  s.homepage    = "http://rubygems.org/gems/lolita"
  s.summary     = %q{CMS for developers}
  s.description = %q{Configurable scaffold tool and CMS for developers}

  s.required_rubygems_version = ">=1.3.6"
  s.rubyforge_project = "lolita"

  s.add_development_dependency "bundler", ">=1.0.2"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib","app"]
end
