ENV["RAILS_ENV"] ||= "test"

require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
end

require 'active_support/all'
require 'active_record'
require 'rspec'
require 'authentication'

# Provide a fixed site salt to avoid relying on Rails.root
AUTHENTICATION_SALT = 'test-salt'

# Configure timezone used by the code under test
Time.zone = 'UTC'

# Minimal DB setup (sqlite3 file for persistence across examples)
DB_PATH = File.expand_path('../tmp/authentication_plugin_test.sqlite3.db', __dir__)
require 'fileutils'
FileUtils.mkdir_p(File.dirname(DB_PATH))

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: DB_PATH
)

# Define the schema used for tests (inlined from legacy test schema)
ActiveRecord::Schema.define(version: 0) do
  create_table :users, force: true do |t|
    t.column :name, :string
    t.column :first_name, :string
    t.column :last_name, :string
    t.column :password_hash, :string, limit: 40
    t.column :password_salt, :string, limit: 40
    t.column :token_key, :string, limit: 40
    t.column :token_expiration, :datetime
    t.column :remember_me, :string, limit: 40
  end
end

# Base test model used by specs
class User < ActiveRecord::Base
  acts_as_authenticated_user
end

RSpec.configure do |config|
  # Clean tables between examples (simple and good enough for this gem)
  config.before do
    ActiveRecord::Base.connection.execute('DELETE FROM users')
  end

  config.order = :random
  Kernel.srand config.seed
end
