#!/usr/bin/env rake
require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList[
    "test/functional/smoke_test.rb",
    "test/functional/admin_sections_smoke_test.rb",
    "test/unit/article_basic_test.rb",
    "test/functional/base_controller_test.rb",
    "test/functional/page_articles_controller_test.rb",
    "test/functional/password_controller_test.rb",
    "test/functional/admin/categories_controller_test.rb",
    "test/functional/admin/users_controller_test.rb"
  ]
  t.warning = false
end

task :default => :test
