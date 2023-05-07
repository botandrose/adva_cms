require "rails"
require "will_paginate"
require "awesome_nested_set"
require "actionpack/page_caching"
require "rails-observers"

require "rails_ext"

# load vendored gems
Dir["#{File.expand_path("#{__dir__}/../vendor/gems")}/**/lib"].each do |vendored_gem_path|
  $: << vendored_gem_path
end

require "belongs_to_cacheable"
require "cacheable_flash"
require "filtered_column"
require "simple_taggable"
require "tags"
require "table_builder"
require "authentication"
require "adva/event"
require "adva/extensible_forms"

module Adva
  class Engine < Rails::Engine
    initializer "add assets to precompilation list" do |app|
      app.config.assets.precompile += %w(adva_cms/application.js)
      app.config.assets.precompile += %w(adva_cms/admin.css)
      app.config.assets.precompile += %w(admin.css admin.js)

      app.config.assets.precompile += %w(adva_cms/icons/tick.png adva_cms/icons/cross.png)
    end

    initializer "adva_user.init" do
      Adva::Event.observers << 'PasswordMailer'
    end
  end
end

