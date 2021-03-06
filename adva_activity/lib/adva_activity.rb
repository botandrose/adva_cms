# require "adva_activity/version"
require "rails"
require "rails-observers"

module AdvaActivity
  module SiteExtensions
    def self.included base
      base.has_many :activities, :dependent => :destroy
    end

    def grouped_activities
      activities.find_coinciding_grouped_by_dates(Time.zone.now.to_date, 1.day.ago.to_date)
    end
  end

  module HasManyActivities
    def self.included base
      base.has_many :activities, :as => :object
    end
  end

  class Engine < Rails::Engine
    initializer "add assets to precompilation list" do |app|
      app.config.assets.precompile += %w(adva_activity/admin/activities.css)
    end

    config.to_prepare do
      Site.send :include, SiteExtensions
      Content.send :include, HasManyActivities
      Comment.send :include, HasManyActivities if defined?(Comment)
    end
  end
end
