ActiveSupport::Reloader.to_prepare do
  Comment.acts_as_role_context :parent => :commentable
end
