# require "adva_blog/version"
require "rails"

module AdvaBlog
  class Engine < Rails::Engine
    initializer "adva_blog.init" do
      Section.register_type 'Blog'
    end
  end
end
