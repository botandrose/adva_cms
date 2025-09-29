require 'simplecov'
require 'simplecov-html'
require 'debug'

SimpleCov.start 'rails' do
  add_filter '/spec/'
  add_filter '/vendor/'
  add_filter '/lib/adva/version.rb'

  add_group 'Controllers', 'app/controllers'
  add_group 'Models', 'app/models'
  add_group 'Helpers', 'app/helpers'
  add_group 'Observers', 'app/observers'
  add_group 'Libraries', 'lib'

  formatter SimpleCov::Formatter::HTMLFormatter
end

RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

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
