if ENV["COVERAGE"]
  require "coverage"
  require "json"
  require "fileutils"
  begin
    Coverage.start(lines: true)
  rescue ArgumentError
    Coverage.start
  end
end

RSpec.configure do |config|
  # Allow both syntaxes to avoid conflicts with vendored specs
  config.expect_with :rspec do |c|
    c.syntax = [:expect, :should]
  end

  config.mock_with :rspec do |m|
    m.syntax = :expect
    m.verify_partial_doubles = true
  end

  config.filter_rails_from_backtrace! if config.respond_to?(:filter_rails_from_backtrace!)
end
