require "rails_helper"

RSpec.describe "Admin::BaseController", type: :request do
  let!(:site) { Site.create!(name: 'Test Site', title: 'Test Site Title', host: 'admin-test.example.com') }
  let!(:admin_user) { User.create!(first_name: 'Admin', email: 'admin@example.com', password: 'AAbbcc1122!!', verified_at: Time.now, admin: true) }
  let!(:regular_user) { User.create!(first_name: 'User', email: 'user@example.com', password: 'AAbbcc1122!!', verified_at: Time.now, admin: false) }

  before { host! site.host }

  describe "authentication and authorization" do
    context "when not logged in" do
      it "redirects to login page" do
        get "/admin/sites"
        expect(response).to redirect_to(login_url(return_to: request.url))
      end
    end

    context "when logged in as regular user" do
      before do
        post "/session", params: { user: { email: regular_user.email, password: 'AAbbcc1122!!' } }
      end

      it "redirects to login with permission error" do
        get "/admin/sites"
        expect(response).to redirect_to(login_url(return_to: request.url))
      end
    end

    context "when logged in as admin user" do
      before do
        post "/session", params: { user: { email: admin_user.email, password: 'AAbbcc1122!!' } }
      end

      it "allows access to admin area" do
        Site.multi_sites_enabled = true
        get "/admin/sites"
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "locale handling" do
    before do
      post "/session", params: { user: { email: admin_user.email, password: 'AAbbcc1122!!' } }
      Site.multi_sites_enabled = true
    end

    it "sets locale from params when valid" do
      get "/admin/sites?locale=en"
      expect(I18n.locale).to eq(:en)
    end

    it "uses default locale when no locale param" do
      get "/admin/sites"
      expect(I18n.locale).to eq(I18n.default_locale)
    end
  end

  describe "timezone handling" do
    before do
      post "/session", params: { user: { email: admin_user.email, password: 'AAbbcc1122!!' } }
      Site.multi_sites_enabled = true
    end

    it "sets timezone from site settings" do
      site.update!(timezone: 'America/New_York')
      get "/admin/sites"
      expect(Time.zone.name).to eq('America/New_York')
    end
  end

  describe "site and section resolution" do
    let!(:section) { Page.create!(site: site, title: 'Test Page', permalink: 'test-page') }

    before do
      post "/session", params: { user: { email: admin_user.email, password: 'AAbbcc1122!!' } }
    end

    it "resolves site from host" do
      get "/admin/sites/#{site.id}"
      expect(response).to have_http_status(:ok)
    end
  end
end