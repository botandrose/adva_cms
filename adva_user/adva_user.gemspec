# -*- encoding: utf-8 -*-
require File.expand_path('../lib/adva_user/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Micah Geisel"]
  gem.email         = ["micah@botandrose.com"]
  gem.description   = %q{Adva User}
  gem.summary       = %q{Engine for Adva CMS user accounts}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "adva_user"
  gem.require_paths = ["lib"]
  gem.version       = AdvaUser::VERSION
end
