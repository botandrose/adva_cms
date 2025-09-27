ENV["RAILS_ENV"] ||= "test"

# Start SimpleCov before loading Rails
require 'simplecov'
require 'simplecov-html'

SimpleCov.start 'rails' do
  add_filter '/spec/'
  add_filter '/vendor/'
  add_filter '/test/'

  add_group 'Controllers', 'app/controllers'
  add_group 'Models', 'app/models'
  add_group 'Helpers', 'app/helpers'
  add_group 'Observers', 'app/observers'
  add_group 'Libraries', 'lib'

  formatter SimpleCov::Formatter::HTMLFormatter
end

require File.expand_path("internal/config/environment", __dir__)
require "rspec/rails"

# Keep Rails 7 path helpers in specs
begin
  require "rails-controller-testing"
  %i[assigns assert_template].each do |_|
    # no-op; the gem mixes into test frameworks, not RSpec; request specs won't need these
  end
rescue LoadError
end

Dir[File.join(__dir__, "support", "**", "*.rb")].sort.each { |f| require f }

RSpec.configure do |config|
  # Enable transactional fixtures (faster than truncation)
  config.use_transactional_fixtures = true

  # Disable CSRF in request specs to avoid 422 on form posts
  config.before do
    if defined?(ActionController::Base)
      ActionController::Base.allow_forgery_protection = false
    end
  end
  # Enable exception handling for most specs, but allow it to be overridden
  config.before(type: :request) do
    if defined?(Rails) && Rails.respond_to?(:application)
      # Allow rescue_from to work by enabling exception handling
      Rails.application.env_config["action_dispatch.show_exceptions"] = true
      Rails.application.env_config["action_dispatch.show_detailed_exceptions"] = false
    end
  end

  # Set default locale to en for consistency
  config.before do
    I18n.default_locale = :en
    I18n.locale = :en
  end

  # Stub event system to prevent email sending during tests
  config.before do
    # Stub trigger_event methods to prevent email sending
    allow_any_instance_of(ActionController::Base).to receive(:trigger_event)
    allow_any_instance_of(ActionController::Base).to receive(:trigger_events)
  end
end
