# require "adva_cms/version"
require "rails"
require "will_paginate"
require "awesome_nested_set"
require "actionpack/page_caching"

require 'extensible_forms'
require 'time_hacks'
require 'core_ext'
require 'rails_ext'
require "rails-observers"

# require 'menu'
# require 'event'    # need to force these to be loaded now, so Rails won't
# require 'registry' # reload them between requests (FIXME ... this doesn't seem to happen?)

# config.to_prepare do
#   Registry.set :redirect, {
#     :login        => lambda { |c| c.send(:admin_sites_url) },
#     :verify       => '/',
#     :site_deleted => lambda { |c| c.send(:admin_sites_url) }
#   }
# end 
# load vendored gems
Dir["#{File.expand_path("#{File.dirname(__FILE__)}/../vendor/gems")}/**/lib"].each do |vendored_gem_path|
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

module Adva
  class Engine < Rails::Engine
    initializer "add assets to precompilation list" do |app|
      app.config.assets.precompile += %w(adva_cms/application.js)
      app.config.assets.precompile += %w(adva_cms/admin.css adva_cms/admin/activities.css)
      app.config.assets.precompile += %w(admin.css admin.js)
    end

    initializer "setup xss_terminate" do
      XssTerminate.untaint_after_find = true
    end

    initializer "adva_user.init" do
      ActionController::Base.send :include, ActionController::AuthenticateUser
      ActionController::Base.send :include, ActionController::AuthenticateAnonymous
      ActiveRecord::Base.send :include, ActiveRecord::BelongsToAuthor
      ActionView::Base.send :include, Login::HelperIntegration

      Event.observers << 'PasswordMailer'
    end
  end
end

require "action_controller/authenticate_user"
require "action_controller/authenticate_anonymous"
require "active_record/belongs_to_author"
require "login/helper_integration"

