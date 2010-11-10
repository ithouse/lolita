# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "lolita/version"

Gem::Specification.new do |s|
  s.name        = "lolita"
  s.version     = Lolita::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Artūrs Meisters", "ITHouse"]
  s.email       = ["arturs@ithouse.lv"]
  s.homepage    = "http://rubygems.org/gems/lolita"
  s.summary     = %q{CMS for developers}
  s.description = %q{CMS for developers}

  s.rubyforge_project = "lolita"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
