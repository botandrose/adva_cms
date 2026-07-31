require "rails_helper"

RSpec.describe "Token login", type: :request do
  let!(:site) { Site.find_by_host("site-with-pages.com") || Site.create!(name: "site with pages", title: "site with pages title", host: "site-with-pages.com") }
  let!(:user) { User.create!(first_name: "Target", email: "target@example.com", password: "AAbbcc1122!!", verified_at: Time.now) }

  before { host! site.host }

  it "logs in as the target user with a token from User#login_as_token" do
    get token_login_path(token: user.login_as_token)
    expect(response).to redirect_to("/admin")
    expect(response.cookies["uid"]).to eq(user.id.to_s)
    expect(response.cookies["uname"]).to eq("Target")
  end

  it "rejects an expired token" do
    token = user.login_as_token(expires_in: 0.seconds)
    sleep 0.1
    get token_login_path(token: token)
    expect(response).to redirect_to("/login")
  end

  # Without a purpose, any "login_as" token ever signed stays valid forever and
  # can only be revoked by rotating secret_key_base.
  it "rejects a token signed without our purpose" do
    token = Rails.application.message_verifier("login_as")
      .generate(user.id, expires_in: 5.minutes)
    get token_login_path(token: token)
    expect(response).to redirect_to("/login")
  end

  it "rejects a token signed for a different purpose" do
    token = Rails.application.message_verifier("login_as")
      .generate(user.id, purpose: :something_else, expires_in: 5.minutes)
    get token_login_path(token: token)
    expect(response).to redirect_to("/login")
  end

  it "rejects an invalid token" do
    get token_login_path(token: "garbage")
    expect(response).to redirect_to("/login")
  end

  it "rejects a blank token" do
    get token_login_path(token: "")
    expect(response).to redirect_to("/login")
  end

  it "rejects a token for a nonexistent user" do
    token = User.new(id: 0).login_as_token
    get token_login_path(token: token)
    expect(response).to redirect_to("/login")
  end
end
