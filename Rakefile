#!/usr/bin/env rake
require "bundler/gem_tasks"


task :default => :spec

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

namespace :spec do
  desc 'Run `rake` in all vendor gem subdirectories (fails if any fail)'
  task :gems do
    failed = []
    bundler_wrapper = Bundler.respond_to?(:with_unbundled_env) ? :with_unbundled_env : :with_clean_env

    Dir.glob('vendor/gems/*').each do |dir|
      puts "==> Running `rake` in #{dir}"
      ok = Bundler.send(bundler_wrapper) do
        system('bundle', chdir: dir)
        system('bundle exec rake', chdir: dir)
      end

      failed << dir unless ok
    end

    unless failed.empty?
      abort "Vendor gem rake failed for: #{failed.join(', ')}"
    end

    puts 'All vendor gem rake runs succeeded.'
  end
end
