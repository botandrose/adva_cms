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
  # gem.add_dependency "labelled_form" # legacy; disabled for Rails 7/8 CI
  # gem.add_dependency "ckeditor"      # legacy asset gem; not needed in test env
  gem.add_dependency "nacelle"
  gem.add_dependency "friendly_id", ">= 5.4"
  gem.add_dependency "actionpack-page_caching"
  gem.add_dependency "rails-observers"
  gem.add_dependency "sassc-rails"

  gem.add_development_dependency "appraisal"
  gem.add_development_dependency "rspec-rails", "~> 6.1"
  gem.add_development_dependency "rails-controller-testing", "~> 1.0"
  gem.add_development_dependency "haml", ">= 6.0"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "simplecov", "~> 0.22"
  gem.add_development_dependency "simplecov-html", "~> 0.13"
  gem.add_development_dependency "sqlite3", "~> 1.7"
end
