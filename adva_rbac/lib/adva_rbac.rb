require "adva_rbac/version"
require "rails"

require "rbac"
require "rbac/role_type/static"
# require "active_record/acts_as_role_context"
require "action_controller/guards_permissions"

module AdvaRbac
  class Engine < Rails::Engine
    initializer "adva_rbac.init" do
      ActiveRecord::Base.send :include, Rbac::ActsAsRoleContext
      ActionController::Base.send :include, ActionController::GuardsPermissions

      Rbac::RoleType.implementation = Rbac::RoleType::Static
    end
  end
end
