ActiveSupport::Reloader.to_prepare do
  BaseController.class_eval { helper :roles }
  Admin::BaseController.class_eval { helper :roles }
end
