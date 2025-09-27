# -*- encoding: utf-8 -*-
require File.expand_path('../lib/tags/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Micah Geisel"]
  gem.email         = ["micah@botandrose.com"]
  gem.description   = %q{HTML tag rendering library}
  gem.summary       = %q{HTML tag rendering library}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "tags"
  gem.require_paths = ["lib"]
  gem.version       = Tags::VERSION

  gem.add_development_dependency "rspec"
  gem.add_development_dependency "nokogiri"
  gem.add_development_dependency "actionview"
  gem.add_development_dependency "activesupport"
  gem.add_development_dependency "actionpack"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "simplecov"
end
