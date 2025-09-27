# -*- encoding: utf-8 -*-
require File.expand_path('../lib/simple_taggable/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Micah Geisel"]
  gem.email         = ["micah@botandrose.com"]
  gem.description   = %q{simple implementation of acts_as_taggable}
  gem.summary       = %q{simple implementation of acts_as_taggable}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "simple_taggable"
  gem.require_paths = ["lib"]
  gem.version       = SimpleTaggable::VERSION

  gem.add_dependency "activerecord"

  gem.add_development_dependency "rspec"
  gem.add_development_dependency "sqlite3"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "simplecov"
end
