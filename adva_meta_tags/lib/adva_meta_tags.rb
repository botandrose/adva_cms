require "adva_meta_tags/version"
require "rails"

module AdvaMetaTags
  class Engine < Rails::Engine
    initializer "adva_meta_tags.init" do
      BaseController.helper :meta_tags
      Admin::BaseController.helper :meta_tags
    end
  end
end
