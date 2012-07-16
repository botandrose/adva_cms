require "adva_user/version"
require "rails"

require "action_controller/authenticate_user"
require "action_controller/authenticate_anonymous"
require "active_record/belongs_to_author"
require "login/helper_integration"

module AdvaUser
  class Engine < Rails::Engine
    initializer "adva_user.init" do
      ActionController::Base.send :include, ActionController::AuthenticateUser
      ActionController::Base.send :include, ActionController::AuthenticateAnonymous
      ActiveRecord::Base.send :include, ActiveRecord::BelongsToAuthor
      ActionView::Base.send :include, Login::HelperIntegration

      Event.observers << 'UserMailer'
      Event.observers << 'PasswordMailer'
    end
  end
end
