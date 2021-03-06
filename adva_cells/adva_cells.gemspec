# -*- encoding: utf-8 -*-
require File.expand_path('../lib/adva_cells/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Micah Geisel"]
  gem.email         = ["micah@botandrose.com"]
  gem.description   = %q{Adva Cells}
  gem.summary       = %q{Engine for Adva CMS embedable cells}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "adva_cells"
  gem.require_paths = ["lib"]
  gem.version       = AdvaCells::VERSION

  gem.add_dependency "cells"
  gem.add_dependency "tilt"
end
