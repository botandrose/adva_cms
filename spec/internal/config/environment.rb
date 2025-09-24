# frozen_string_literal: true

require_relative "application"

# Ensure the engine code is loaded (models/constants used in migrations)
require "bundler/setup"
require "adva"
Internal::Application.configure do
  config.consider_all_requests_local = true
  config.action_dispatch.show_exceptions = false
end
require "menu"
# Make TableBuilder helper available
require "table_builder"
# Ensure Haml templates can render
begin
  require "haml"
rescue LoadError
end
# Load simple tag/breadcrumb helpers from vendored tags (needed by admin header)
$LOAD_PATH.unshift File.expand_path("../../../../vendor/gems/tags/lib", __FILE__)
begin
  require "tags"
rescue LoadError
end

# Ensure all vendor gems are on the load path
Dir[File.expand_path("../../../../vendor/gems/*/lib", __FILE__)].each do |lib_path|
  $LOAD_PATH.unshift lib_path unless $LOAD_PATH.include?(lib_path)
end

# Load cacheable_flash so controller includes resolve
begin
  require "cacheable_flash"
rescue LoadError
end

# Configure an in-memory or file-based sqlite database for tests
require "fileutils"
FileUtils.mkdir_p(File.expand_path("../../tmp", __dir__))
db_path = File.expand_path("../../tmp/test.sqlite3", __dir__)

# Remove existing database to start fresh
FileUtils.rm_f(db_path) if File.exist?(db_path)

ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: db_path
)

# Run engine migrations BEFORE app init (schema-only migrations)
migrations_paths = [File.expand_path("../../../../db/migrate", __FILE__)]
if defined?(ActiveRecord::MigrationContext)
  context = ActiveRecord::MigrationContext.new(migrations_paths)
  if context.respond_to?(:migrate)
    context.migrate
  else
    context.up
  end
else
  ActiveRecord::Migrator.migrate(migrations_paths)
end

# Now initialize the application
Internal::Application.initialize!

# Load the engine's routes into this dummy app (after DB exists and app init)
engine_routes = File.expand_path("../../../../config/routes.rb", __FILE__)
load engine_routes if File.exist?(engine_routes)

# Seed minimal data for tests if empty (after init)
seed_file = File.expand_path("../db/seed_for_tests.rb", __dir__)
load seed_file if File.exist?(seed_file)
