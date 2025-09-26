#!/usr/bin/env rake
require "bundler/gem_tasks"


task :default => [:spec, :vendor_gems_tests]

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.rspec_opts = ["--format", "documentation", "--color"]
  end
  desc "Run RSpec suite"
rescue LoadError
  # rspec-rails not installed yet; task will be unavailable until bundle install
end

desc "Run test suites for all gems in vendor/gems"
task :vendor_gems_tests do
  vendor_gems_dir = File.expand_path('vendor/gems', __dir__)
  failed_gems = []
  success_count = 0

  Dir.glob("#{vendor_gems_dir}/*").each do |gem_dir|
    next unless File.directory?(gem_dir)
    gem_name = File.basename(gem_dir)

    Dir.chdir(gem_dir) do
      puts "\n=== Running tests for #{gem_name} ==="

      test_ran = false
      test_passed = false

      # Try different test approaches in order of preference
      if File.exist?('Rakefile')
        # Check what tasks are available first
        available_tasks = `rake --tasks 2>/dev/null`.lines.map { |line| line.split.first }.compact

        if available_tasks.include?('rake') && available_tasks.any? { |task| task.match?(/test|spec/) }
          # Has proper rake tasks, try them
          if available_tasks.include?('rake') && available_tasks.include?('default')
            test_ran = true
            test_passed = system('rake default 2>/dev/null')
          elsif available_tasks.any? { |task| task == 'test' }
            test_ran = true
            test_passed = system('rake test 2>/dev/null')
          elsif available_tasks.any? { |task| task == 'spec' }
            test_ran = true
            test_passed = system('rake spec 2>/dev/null')
          end
        end
      end

      # Fallback: run tests directly if rake approach failed
      unless test_ran && test_passed
        if Dir.exist?('test')
          test_files = Dir.glob('test/**/*_test.rb')
          unless test_files.empty?
            puts "Running tests directly..."
            test_ran = true
            test_passed = system("ruby -Ilib:test #{test_files.join(' ')}")
          end
        elsif Dir.exist?('spec')
          spec_files = Dir.glob('spec/**/*_spec.rb')
          unless spec_files.empty?
            puts "Running specs directly..."
            test_ran = true
            if system('which rspec > /dev/null 2>&1')
              test_passed = system('rspec')
            end
          end
        end
      end

      # Report results
      if test_ran
        if test_passed
          puts "✓ Tests passed for #{gem_name}"
          success_count += 1
        else
          puts "✗ Tests failed for #{gem_name}"
          failed_gems << gem_name
        end
      else
        puts "- No tests found for #{gem_name}"
      end
    end
  end

  puts "\n=== Vendor gems test summary ==="
  puts "#{success_count} gems passed tests"
  unless failed_gems.empty?
    puts "#{failed_gems.size} gems failed tests: #{failed_gems.join(', ')}"
    abort "Vendor gems tests failed!"
  end
end

 
