# -*- encoding: utf-8 -*-
require File.expand_path('../lib/authentication/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Micah Geisel"]
  gem.email         = ["micah@botandrose.com"]
  gem.description   = %q{Default adva authentication library}
  gem.summary       = %q{Default adva authentication library}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "authentication"
  gem.require_paths = ["lib"]
  gem.version       = Authentication::VERSION

  gem.add_dependency "activerecord"
  gem.add_dependency "activesupport"

  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec", "~>3.0"
  gem.add_development_dependency "sqlite3", "~>2.0"
  gem.add_development_dependency "simplecov"
end
