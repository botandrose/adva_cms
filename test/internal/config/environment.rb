# frozen_string_literal: true

require_relative "application"

# Ensure the engine code is loaded (models/constants used in migrations)
require "bundler/setup"
require "adva"

# Configure an in-memory or file-based sqlite database for tests
require "fileutils"
FileUtils.mkdir_p(File.expand_path("../../tmp", __dir__))
ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: File.expand_path("../../tmp/test.sqlite3", __dir__)
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
