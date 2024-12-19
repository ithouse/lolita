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
  s.description = %q{Manage Rails, application backend with ease.}

  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md"
  ]
  s.licenses = ["MIT"]

  s.add_dependency(%q<kaminari>, [">= 1.0.0"])
  s.add_dependency(%q<abstract>, ["~> 1.0.0"])
  s.add_dependency(%q<haml>, [">= 3.0.0"])
  s.add_dependency(%q<activesupport>, [">= 3.2.0"])
  s.add_dependency(%q<railties>, [">= 3.2.0"])
  s.add_dependency(%q<jquery-rails>, [">0"])
  s.add_dependency(%q<jquery-ui-rails>, [">0"])
  s.add_dependency(%q<tinymce-rails>, ["~> 4.1"])
  s.add_dependency(%q<tinymce-rails-langs>, ["~> 4.0"])

  s.files = `git ls-files`.split($/)
  s.executables = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]
end
