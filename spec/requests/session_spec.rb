require "rails_helper"

RSpec.describe "Session", type: :request do
  let!(:site) { Site.find_by_host("site-with-pages.com") || Site.create!(name: "site with pages", title: "site with pages title", host: "site-with-pages.com") }

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
    let!(:user) { User.find_by_email("a-user@example.com") || User.create!(first_name: "a user", email: "a-user@example.com", password: "AAbbcc1122!!", verified_at: Time.now) }

    it "fails with wrong credentials" do
      host! site.host
      post "/session", params: { user: { email: "nobody@example.com", password: "wrong" } }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('name="user[email]"')
      # Should render login form again
      expect(response.body).to include('action="/session"')
    end

    it "fails with wrong password for existing user" do
      host! site.host
      post "/session", params: { user: { email: user.email, password: "wrong" } }
      expect(response).to have_http_status(:ok)
      # Should render login form again with email prefilled
      expect(response.body).to include(user.email)
      expect(response.body).to include('action="/session"')
    end

    it "succeeds with valid credentials" do
      host! site.host
      post "/session", params: { user: { email: user.email, password: "AAbbcc1122!!" }, return_to: "/" }
      expect(response).to redirect_to("/")
    end

    it "redirects to default path when no return_to specified" do
      host! site.host
      post "/session", params: { user: { email: user.email, password: "AAbbcc1122!!" } }
      expect(response).to redirect_to("/")
    end

    it "redirects to return_to path when specified" do
      host! site.host
      post "/session", params: { user: { email: user.email, password: "AAbbcc1122!!" }, return_to: "/special-page" }
      expect(response).to redirect_to("/special-page")
    end

    def credentials_set_cookie
      Array(response.headers["Set-Cookie"]).join("\n").split("\n").find do |line|
        line.start_with?("user_credentials=")
      end
    end

    it "outlives the browser session when remember me is requested" do
      host! site.host
      post "/session", params: { user: { email: user.email, password: "AAbbcc1122!!", remember_me: "1" } }
      expect(response).to redirect_to("/")
      expect(response.cookies["user_credentials"]).to be_present

      expires = credentials_set_cookie[/;\s*expires=([^;]+)/i, 1]
      expect(expires).to be_present
      expect(Time.parse(expires)).to be_within(1.hour).of(2.weeks.from_now)
    end

    it "expires with the browser session when remember me is not requested" do
      host! site.host
      post "/session", params: { user: { email: user.email, password: "AAbbcc1122!!" } }
      expect(response).to redirect_to("/")
      # Authlogic always persists the session by cookie; without remember me it
      # simply carries no expiry.
      expect(response.cookies["user_credentials"]).to be_present
      expect(credentials_set_cookie).not_to match(/;\s*expires=/i)
    end

    it "hardens the credentials cookie with httponly, secure, and same_site=lax" do
      host! site.host
      post "/session", params: { user: { email: user.email, password: "AAbbcc1122!!", remember_me: "1" } }
      expect(response.cookies["user_credentials"]).to be_present

      set_cookie = credentials_set_cookie
      expect(set_cookie).to be_present
      expect(set_cookie).to match(/;\s*httponly/i)
      expect(set_cookie).to match(/;\s*secure/i)
      expect(set_cookie).to match(/;\s*samesite=lax/i)
    end

    it "logs in an account whose bcrypt hash was written before authlogic" do
      # What the previous scheme stored: bcrypt over the password alone, with an
      # unrelated salt sitting in password_salt.
      user.update_columns(
        password_salt: Digest::SHA1.hexdigest("salt-whenever"),
        password_hash: BCrypt::Password.create("AAbbcc1122!!").to_s,
      )

      host! site.host
      post "/session", params: { user: { email: user.email, password: "AAbbcc1122!!" } }
      expect(response).to redirect_to("/")
    end

    it "logs in an account still on the legacy sha1 hash, rehashing it to bcrypt" do
      salt = Digest::SHA1.hexdigest("some-legacy-salt")
      user.update_columns(
        password_salt: salt,
        password_hash: Digest::SHA1.hexdigest("#{salt}---AAbbcc1122!!"),
      )

      host! site.host
      post "/session", params: { user: { email: user.email, password: "AAbbcc1122!!" } }
      expect(response).to redirect_to("/")

      expect(user.reload.password_hash).to start_with("$2")
    end

    it "refuses to log in an unverified account" do
      unverified = User.create!(first_name: "unverified",
        email: "unverified@example.com", password: "AAbbcc1122!!")

      host! site.host
      post "/session", params: { user: { email: unverified.email, password: "AAbbcc1122!!" } }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('action="/session"')
    end

    it "preserves remember_me value on failed login" do
      host! site.host
      post "/session", params: { user: { email: user.email, password: "wrong", remember_me: "1" } }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("checked")
    end
  end

  describe "DELETE /session" do
    let!(:user) { User.find_by_email("a-user@example.com") || User.create!(first_name: "a user", email: "a-user@example.com", password: "AAbbcc1122!!", verified_at: Time.now) }

    it "logs out the user" do
      host! site.host
      # First log in
      post "/session", params: { user: { email: user.email, password: "AAbbcc1122!!" } }
      expect(response).to redirect_to("/")

      # Then log out
      delete "/session"
      expect(response).to redirect_to("/")
    end

    it "can be called when not logged in" do
      host! site.host
      delete "/session"
      expect(response).to redirect_to("/")
    end

    it "clears the credentials cookie on logout" do
      host! site.host
      post "/session", params: { user: { email: user.email, password: "AAbbcc1122!!", remember_me: "1" } }
      expect(response.cookies["user_credentials"]).to be_present

      delete "/session"
      expect(response).to redirect_to("/")
      expect(response.cookies["user_credentials"]).to be_blank
    end
  end
end

