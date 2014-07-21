# -*- encoding: utf-8 -*-
require File.expand_path('../lib/adva_cms/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Micah Geisel"]
  gem.email         = ["micah@botandrose.com"]
  gem.description   = %q{Adva CMS}
  gem.summary       = %q{Engine for Adva CMS core}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "adva_cms"
  gem.require_paths = ["lib"]
  gem.version       = AdvaCms::VERSION

  gem.add_dependency "will_paginate"
  gem.add_dependency "awesome_nested_set"
  gem.add_dependency "friendly_id"
end
