# frozen_string_literal: true

require "rails/all"

module Internal
  class Application < Rails::Application
    config.root = File.expand_path("..", __dir__)
    if Rails::VERSION::MAJOR >= 8
      config.load_defaults 8.0
    else
      config.load_defaults 7.2
    end
    config.eager_load = false
    config.hosts.clear
    config.secret_key_base = "test_secret_key_base_please_change"

    # Match a real Rails test env so Secure cookies are still written over the
    # simulated HTTP requests used by request specs.
    config.action_dispatch.always_write_cookie = true

    # Ensure ActiveRecord::RecordNotFound is handled as 404
    config.action_dispatch.rescue_responses.merge!(
      "ActiveRecord::RecordNotFound" => :not_found
    )
  end
end
