# -*- encoding: utf-8 -*-
require File.expand_path('../lib/table_builder/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Micah Geisel"]
  gem.email         = ["micah@botandrose.com"]
  gem.description   = %q{Turns data structures into HTML tables.}
  gem.summary       = %q{Turns data structures into HTML tables.}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "table_builder"
  gem.require_paths = ["lib"]
  gem.version       = TableBuilder::VERSION

  gem.add_development_dependency "rspec"
  gem.add_development_dependency "nokogiri"
  gem.add_development_dependency "actionview"
  gem.add_development_dependency "activesupport"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "simplecov"
end
