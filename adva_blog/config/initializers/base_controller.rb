ActionDispatch::Callbacks.to_prepare do
  BaseController.class_eval { helper BlogHelper }
end
