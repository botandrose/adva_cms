# Plugin specific configuration and helper functions
class Test::Unit::TestCase
  # Turn off transactional tests/fixtures for compatibility across AR versions
  if respond_to?(:use_transactional_tests=)
    self.use_transactional_tests = false
  elsif respond_to?(:use_transactional_fixtures=)
    self.use_transactional_fixtures = false
  end

  # Instantiated fixtures are slow; keep disabled if supported
  self.use_instantiated_fixtures = false if respond_to?(:use_instantiated_fixtures=)
end
