# require "adva_comments/version"
require "rails"

require "active_record/has_many_comments"
require "action_controller/acts_as_commentable"
# require 'format'

module AdvaComments
  class Engine < Rails::Engine
    initializer "add assets to precompilation list" do |app|
      app.config.assets.precompile += %w(adva_cms/admin/comments.css)
    end

    initializer "adva_comments.init" do
      ActiveRecord::Base.send :include, ActiveRecord::HasManyComments
      ActionController::Base.send :include, ActionController::ActsAsCommentable
    end
  end
end
