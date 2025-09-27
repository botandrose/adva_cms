# NOTE: Inherited from acts_as_versioned

$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'test/unit'
# Minimal ActiveRecord + ActiveSupport boot for standalone tests
require 'active_support/all'
require 'active_record'
require 'active_record/fixtures'
require 'authentication'

config = YAML::load(IO.read(File.join(File.dirname(__FILE__), 'database.yml')))
# Provide a fixed site salt to avoid relying on Rails.root
AUTHENTICATION_SALT = 'test-salt'

ActiveRecord::Base.logger =
  Logger.new(File.join(File.dirname(__FILE__), 'debug.log'))

# Normalize legacy DB config keys for modern ActiveRecord
db_conf = config[ENV['DB'] || 'sqlite3']
db_conf = db_conf.transform_keys { |k| k.is_a?(Symbol) ? k : k.to_s.sub(/^:/, '').to_sym }
if db_conf[:dbfile] && !db_conf[:database]
  db_conf[:database] = db_conf.delete(:dbfile)
end
if db_conf[:adapter].to_s == 'sqlite'
  db_conf[:adapter] = 'sqlite3'
end
ActiveRecord::Base.establish_connection(db_conf)

# Configure a default time zone for ActiveSupport helpers used in the code
Time.zone = 'UTC'

load(File.join(File.dirname(__FILE__), 'schema.rb'))

Test::Unit::TestCase.include ActiveRecord::TestFixtures
FIXTURE_DIR = File.join(File.dirname(__FILE__), 'fixtures')
if Test::Unit::TestCase.respond_to?(:fixture_path=)
  Test::Unit::TestCase.fixture_path = FIXTURE_DIR
elsif Test::Unit::TestCase.respond_to?(:fixture_paths=)
  Test::Unit::TestCase.fixture_paths = [FIXTURE_DIR]
end
$LOAD_PATH.unshift(FIXTURE_DIR)

# Ensure the User model used in fixtures is loaded
require File.join(FIXTURE_DIR, 'user')

class Test::Unit::TestCase #:nodoc:
  def create_fixtures(*table_names)
    if block_given?
      Fixtures.create_fixtures(Test::Unit::TestCase.fixture_path, table_names) { yield }
    else
      Fixtures.create_fixtures(Test::Unit::TestCase.fixture_path, table_names)
    end
  end

  require File.join(File.dirname(__FILE__), 'test_helper.rb')
end
