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

  gem.add_dependency "adva_cms", "~>0.1.0"
  gem.add_dependency "adva_user", "~>0.1.0"
  gem.add_dependency "adva_rbac", "~>0.1.0"
  gem.add_dependency "adva_activity", "~>0.1.0"
  gem.add_dependency "adva_meta_tags", "~>0.1.0"
end

