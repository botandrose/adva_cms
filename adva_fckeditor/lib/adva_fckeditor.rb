# require "adva_fckeditor/version"

module AdvaFckeditor
  class Engine < Rails::Engine
    initializer "add assets to precompilation list" do |app|
      require "non-stupid-digest-assets"
      app.config.assets.precompile += [/adva_fckeditor/]
      NonStupidDigestAssets.whitelist = [/adva_fckeditor/]
    end
  end
end

