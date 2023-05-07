# frozen_string_literal: true

require_relative "cacheable_flash/version"
require_relative "cacheable_flash/middleware"
require_relative "cacheable_flash/controller"

module CacheableFlash
  class Engine < ::Rails::Engine
    config.app_middleware.use Middleware
    ActionController::Base.include(Controller)
  end
end
