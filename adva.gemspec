# -*- encoding: utf-8 -*-
require File.expand_path('../lib/adva/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Micah Geisel"]
  gem.email         = ["micah@botandrose.com"]
  gem.description   = %q{Adva CMS}
  gem.summary       = %q{cutting edge cms, blog, wiki, forum}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "adva"
  gem.require_paths = ["lib"]
  gem.version       = Adva::VERSION
end
