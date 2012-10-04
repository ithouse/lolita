# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "lolita/version"

Gem::Specification.new do |s|
  s.name        = "lolita"
  s.version     = Lolita::Version.to_s
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["ITHouse (Latvia) and Arturs Meisters"]
  s.email       = "support@ithouse.lv"
  s.homepage    = "http://github.com/ithouse/lolita"
  s.summary     = %q{Great web resources management tool}
  s.description = %q{Manage Rails, Sinatra application backend with ease.}

  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md"
  ]
  s.licenses = ["MIT"]

  s.add_dependency(%q<kaminari>, ["~> 0.13.0"])
  s.add_runtime_dependency(%q<abstract>, ["~> 1"])
  s.add_runtime_dependency(%q<haml>, ["~> 3.1.2"])
  s.add_runtime_dependency(%q<activesupport>,["~>3.2.0"])
  s.add_dependency(%q<jquery-rails>, [">=2"])
  s.add_dependency(%q<tinymce-rails-config-manager>,[">=0"])

  s.add_development_dependency(%q<fabrication>, ["~> 1.3.2"])
  s.add_development_dependency(%q<cover_me>, ["~> 1.2.0"])
  s.add_development_dependency(%q<rspec>, ["~> 2.9.0"])
  s.add_development_dependency(%q<capybara>, ["~> 1.1.2"])
  s.add_development_dependency(%q<capybara-webkit>, ["~> 0.11.0"])
  s.add_development_dependency(%q<ffaker>, ["~> 1"])

  s.files = Dir["{app,config,db,lib}/**/*"] + ["Rakefile", "README.md"]
  s.test_files    = Dir["{spec}/**/*"]
  s.require_paths = ["lib"]
end
