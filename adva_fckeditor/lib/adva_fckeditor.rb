# require "adva_fckeditor/version"

module AdvaFckeditor
  class Engine < Rails::Engine
    initializer "add assets to precompilation list" do |app|
      require "non-stupid-digest-assets"
      assets = [/adva_fckeditor/, "fck_config.js", "fck_editor.css"]
      app.config.assets.precompile += assets
      NonStupidDigestAssets.whitelist = assets
    end
  end
end

