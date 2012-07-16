require "adva_activity/version"
require "rails"

module AdvaActivity
  module SiteExtensions
    def self.included base
      base.has_many :activities, :dependent => :destroy
    end
  end

  class Engine < Rails::Engine
    config.to_prepare do
      Site.send :include, SiteExtensions
    end
  end
end
