require "adva_cms/version"
require "rails"
require "globalize3"
require "will_paginate"

require 'extensible_forms'
require 'time_hacks'
require 'core_ext'
require 'rails_ext'
require 'cells_ext'

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

module AdvaCms
  class Engine < Rails::Engine
    initializer "load_vendored_gems" do
      Dir["#{File.expand_path("#{File.dirname(__FILE__)}/../vendor/gems")}/**/lib"].each do |vendored_gem_path|
        $: << vendored_gem_path
      end
      require "has_counter"
      require "belongs_to_cacheable"
      require "filtered_column"
    end
  end
end
