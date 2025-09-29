require "rails_helper"

RSpec.describe "Admin::Users", type: :request do
  let!(:site) { Site.find_by_host('site-with-pages.com') || Site.create!(name: 'site with pages', title: 'site with pages title', host: 'site-with-pages.com') }

  it "redirects anonymous users to login on index" do
    host! site.host
    get admin_users_path
    expect(response).to redirect_to(login_url(return_to: admin_users_url))
  end

  context "as admin" do
    before do
      host! site.host
      login_as_admin
    end

    it "renders index and builds users list" do
      # ensure there is at least one site member and one admin in the system
      site_member = User.create!(first_name: 'Site', email: 'site-member@example.com', password: 'AAbbcc1122!!', verified_at: Time.now)
      site.memberships.create!(user: site_member)

      # an explicit admin record to populate User.admin scope
      User.create!(first_name: 'Admin', email: 'another-admin@example.com', password: 'AAbbcc1122!!', verified_at: Time.now, admin: true)

      get admin_users_path
      expect(response).to have_http_status(:ok)
    end

    it "renders new and initializes a new user" do
      get new_admin_user_path
      expect(response).to have_http_status(:ok)
    end
  end
end
