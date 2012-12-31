# require "adva_cells/version"
require "rails"
require "cells"
require "output_filter/cells"

module AdvaCells
  class Engine < Rails::Engine
    initializer "adva_cells.init" do |app|
      app.config.middleware.use "OutputFilter::Cells"
    end
  end
end
