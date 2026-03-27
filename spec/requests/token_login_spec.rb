require "rails_helper"

RSpec.describe "Token login", type: :request do
  let!(:site) { Site.find_by_host("site-with-pages.com") || Site.create!(name: "site with pages", title: "site with pages title", host: "site-with-pages.com") }
  let!(:user) { User.create!(first_name: "Target", email: "target@example.com", password: "AAbbcc1122!!", verified_at: Time.now) }

  before { host! site.host }

  def generate_token(user_id, expires_in: 5.minutes)
    Rails.application.message_verifier("login_as").generate(user_id, expires_in: expires_in)
  end

  it "logs in as the target user with a valid token" do
    get token_login_path(token: generate_token(user.id))
    expect(response).to redirect_to("/admin")
    expect(response.cookies["uid"]).to eq(user.id.to_s)
    expect(response.cookies["uname"]).to eq("Target")
  end

  it "rejects an expired token" do
    token = generate_token(user.id, expires_in: 0.seconds)
    sleep 0.1
    get token_login_path(token: token)
    expect(response).to redirect_to("/login")
  end

  it "rejects an invalid token" do
    get token_login_path(token: "garbage")
    expect(response).to redirect_to("/login")
  end

  it "rejects a token for a nonexistent user" do
    get token_login_path(token: generate_token(0))
    expect(response).to redirect_to("/login")
  end
end
