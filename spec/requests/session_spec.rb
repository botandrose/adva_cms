require "rails_helper"

RSpec.describe "Session", type: :request do
  let!(:site) { Site.find_by_host('site-with-pages.com') || Site.create!(name: 'site with pages', title: 'site with pages title', host: 'site-with-pages.com') }

  describe "GET /login" do
    it "renders the login form" do
      host! site.host
      get "/login"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("<form")
      expect(response.body).to include('name="user[email]"')
    end
  end

  describe "POST /session" do
    it "fails with wrong credentials" do
      host! site.host
      post "/session", params: { user: { email: "nobody@example.com", password: "wrong" } }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('name="user[email]"')
    end

    it "succeeds with valid credentials" do
      user = User.find_by_email('a-user@example.com') || User.create!(first_name: 'a user', email: 'a-user@example.com', password: 'AAbbcc1122!!', verified_at: Time.now)
      host! site.host
      post "/session", params: { user: { email: user.email, password: 'AAbbcc1122!!' }, return_to: '/' }
      expect(response).to redirect_to("/")
    end
  end
end

