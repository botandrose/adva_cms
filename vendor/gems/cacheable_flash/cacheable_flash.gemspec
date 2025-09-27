# frozen_string_literal: true

require_relative "lib/cacheable_flash/version"

Gem::Specification.new do |spec|
  spec.name = "cacheable_flash"
  spec.version = CacheableFlash::VERSION
  spec.authors = ["Micah Geisel"]
  spec.email = ["micah@botandrose.com"]

  spec.summary = "Rails flash messages that can be cached"
  spec.description = "CacheableFlash provides a way to use Rails flash messages in a cache-friendly manner by putting the flash messages in the cookie, and rendering them with javascript."
  spec.required_ruby_version = ">= 3.2.0"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # Development and test dependencies
  spec.add_development_dependency "rspec", ">= 3.12", "< 4"
  spec.add_development_dependency "simplecov", "~> 0.22"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
