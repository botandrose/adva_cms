require "rails_helper"

# A password-reset token is a bearer credential sitting in a URL. It must only
# be able to establish a session on the reset flow that issued it -- #current_user
# runs on every request, so an unscoped token logs you in anywhere.
RSpec.describe "Perishable token login", type: :request do
  let!(:site) { Site.find_by_host("site-with-pages.com") || Site.create!(name: "site with pages", title: "site with pages title", host: "site-with-pages.com") }
  let!(:user) do
    User.create!(
      first_name: "Reset",
      email: "reset-me@example.com",
      password: "AAbbcc1122!!",
      verified_at: Time.now,
      admin: true,
    )
  end

  before { host! site.host }

  it "is opted out by default and opted in on the password controller" do
    expect(BaseController.perishable_token_login).to eq(false)
    expect(Admin::BaseController.perishable_token_login).to eq(false)
    expect(PasswordController.perishable_token_login).to eq(true)
  end

  it "establishes a session on the password reset form" do
    user.reset_perishable_token!

    get "/password/edit", params: { token: user.perishable_token }

    expect(response).to have_http_status(:ok)
    expect(controller.send(:current_user)).to eq(user)
  end

  it "does not establish a session on the admin area" do
    user.reset_perishable_token!

    get "/admin/sites", params: { token: user.perishable_token }

    expect(response).to redirect_to(%r{/login})
  end

  it "ignores a token that is not a valid perishable token" do
    get "/password/edit", params: { token: "not-a-real-token" }

    expect(response).to have_http_status(:ok)
    expect(controller.send(:current_user)).to be_anonymous
  end
end
