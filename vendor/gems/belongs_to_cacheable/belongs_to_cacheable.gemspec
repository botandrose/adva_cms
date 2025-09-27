# -*- encoding: utf-8 -*-
require File.expand_path('../lib/belongs_to_cacheable/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Micah Geisel"]
  gem.email         = ["micah@botandrose.com"]
  gem.description   = %q{belongs_to_cacheable active record extension}
  gem.summary       = %q{belongs_to_cacheable active record extension}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "belongs_to_cacheable"
  gem.require_paths = ["lib"]
  gem.version       = BelongsToCacheable::VERSION

  gem.add_dependency "activerecord"

  gem.add_development_dependency "rspec", "~>3.0"
  gem.add_development_dependency "sqlite3"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "simplecov"
end
