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

  gem.add_dependency "will_paginate"
  gem.add_dependency "awesome_nested_set"
  gem.add_dependency "friendly_id", "~> 5.1.0" # 5.2.0 tries to call #slug= on invalid save
  gem.add_dependency "actionpack-page_caching"
  gem.add_dependency "rails-observers"

  gem.add_dependency "adva_rbac", "~>0.1.0"
end

