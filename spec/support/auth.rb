module SpecAuth
  def login_as_admin
    user = User.find_by_email('admin@example.com') || User.create!(first_name: 'admin', email: 'admin@example.com', password: 'AAbbcc1122!!', verified_at: Time.now)
    # BaseController and Admin::BaseController define current_user via Adva::AuthenticateUser
    allow_any_instance_of(BaseController).to receive(:current_user).and_return(user) if defined?(BaseController)
    allow_any_instance_of(Admin::BaseController).to receive(:current_user).and_return(user) if defined?(Admin::BaseController)
    user.define_singleton_method(:admin?) { true }
    user
  end
end

RSpec.configure do |config|
  config.include SpecAuth, type: :request
end
