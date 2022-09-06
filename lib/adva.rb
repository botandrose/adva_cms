# require "adva_cms/version"
require "rails"
require "will_paginate"
require "awesome_nested_set"
require "actionpack/page_caching"

require "extensible_forms"
require "time_hacks"
require "core_ext"
require "rails_ext"
require "rails-observers"

# load vendored gems
Dir["#{File.expand_path("#{__dir__}/../vendor/gems")}/**/lib"].each do |vendored_gem_path|
  $: << vendored_gem_path
end

require "has_counter"
require "belongs_to_cacheable"
require "filtered_column"
require "has_filter"
require "simple_taggable"
require "tags"
require "table_builder"
require "xss_terminate"
require "authentication"
require "adva/event"
require "adva/authenticate_user"
require "adva/belongs_to_author"
require "adva/current_user"

module Adva
  class Engine < Rails::Engine
    initializer "add assets to precompilation list" do |app|
      app.config.assets.precompile += %w(adva_cms/application.js)
      app.config.assets.precompile += %w(adva_cms/admin.css)
      app.config.assets.precompile += %w(admin.css admin.js)
    end

    initializer "setup xss_terminate" do
      XssTerminate.untaint_after_find = true
    end

    initializer "adva_user.init" do
      ActionController::Base.send :include, Adva::AuthenticateUser
      ActiveRecord::Base.send :include, Adva::BelongsToAuthor
      ActionView::Base.send :include, Adva::CurrentUser

      Adva::Event.observers << 'PasswordMailer'
    end
  end
end

