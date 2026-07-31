require "rails_helper"

# The auth controllers used to opt out of forgery protection wholesale, which
# left login and password-change open to CSRF in every app using adva. The suite
# disables forgery protection globally, so these turn it back on.
#
# PasswordController#update is the exception: a valid perishable token stands in
# for the authenticity token, because the emailed reset link is the credential
# and the session cookie is frequently gone by the time the form is submitted.
# A token cannot be supplied cross-site, so it is not ambient authority.
#
# protect_from_forgery :exception raises InvalidAuthenticityToken; what status
# that becomes is up to the host app's exception mapping, so these assert the
# thing that matters -- the request had no effect.
RSpec.describe "Forgery protection on the auth controllers", type: :request do
  let!(:site) { Site.find_by_host("site-with-pages.com") || Site.create!(name: "site with pages", title: "site with pages title", host: "site-with-pages.com") }
  let!(:user) { User.create!(first_name: "Csrf", email: "csrf@example.com", password: "AAbbcc1122!!", verified_at: Time.now) }

  before do
    host! site.host
    ActionController::Base.allow_forgery_protection = true
  end

  after do
    ActionController::Base.allow_forgery_protection = false
  end

  it "does not log in on a post with no authenticity token" do
    post session_path, params: { user: { email: user.email, password: "AAbbcc1122!!" } }

    expect(response).not_to have_http_status(:success)
    expect(response).not_to have_http_status(:redirect)
    expect(response.cookies["uid"]).to be_nil
  end

  it "does not change the password for a logged in user with no authenticity token" do
    log_in_without_forgery_protection

    put password_path, params: { user: { password: "ZZyyxx9988!!" } }

    expect(user.reload.valid_password?("AAbbcc1122!!")).to be(true)
    expect(user.valid_password?("ZZyyxx9988!!")).to be(false)
  end

  it "does not let an unrecognised token exempt a logged in user from verification" do
    log_in_without_forgery_protection

    put password_path, params: { token: "bogus", user: { password: "ZZyyxx9988!!" } }

    expect(user.reload.valid_password?("AAbbcc1122!!")).to be(true)
    expect(user.valid_password?("ZZyyxx9988!!")).to be(false)
  end

  it "changes the password on a put carrying a valid reset token and no session" do
    user.reset_perishable_token!

    put password_path, params: { token: user.perishable_token, user: { password: "ZZyyxx9988!!" } }

    expect(response).to redirect_to("/")
    expect(user.reload.valid_password?("ZZyyxx9988!!")).to be(true)
  end

  it "logs in normally once forgery protection is satisfied" do
    ActionController::Base.allow_forgery_protection = false

    post session_path, params: { user: { email: user.email, password: "AAbbcc1122!!" } }

    expect(response).to redirect_to("/")
    expect(response.cookies["uid"]).to eq(user.id.to_s)
  end

  it "leaves the verify_authenticity_token callback in place on both controllers" do
    [SessionController, PasswordController].each do |controller|
      filters = controller._process_action_callbacks.map(&:filter)
      expect(filters).to include(:verify_authenticity_token), "#{controller} skips CSRF verification"
    end
  end

  def log_in_without_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    post session_path, params: { user: { email: user.email, password: "AAbbcc1122!!" } }
    expect(response).to redirect_to("/")
    ActionController::Base.allow_forgery_protection = true
  end
end
