#!/usr/bin/env rake
require "bundler/gem_tasks"


task :default => :spec

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.rspec_opts = ["--format", "documentation", "--color"]
  end
  desc "Run RSpec suite"
rescue LoadError
  # rspec-rails not installed yet; task will be unavailable until bundle install
end

 
