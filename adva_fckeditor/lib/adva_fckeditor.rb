# require "adva_fckeditor/version"

module AdvaFckeditor
  class Engine < Rails::Engine
    initializer "add assets to precompilation list" do |app|
      app.config.assets.precompile += %w(adva_fckeditor/setup_fckeditor.js)
    end
  end
end
