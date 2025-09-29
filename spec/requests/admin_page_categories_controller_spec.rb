require "rails_helper"

RSpec.describe "Admin::Page::CategoriesController", type: :request do
  let!(:site) { Site.create!(name: 'Cats Site', title: 'Cats', host: 'cats.example.com') }
  let!(:section) { Page.create!(site: site, title: 'Cats Page', permalink: 'cats-page', published_at: 1.hour.ago) }
  let!(:admin_user) { User.create!(first_name: 'Admin', email: 'cats-admin@example.com', password: 'AAbbcc1122!!', verified_at: Time.now, admin: true) }

  before do
    host! site.host
    post "/session", params: { user: { email: admin_user.email, password: 'AAbbcc1122!!' } }
  end

  describe "GET /admin/pages/:page_id/categories/new" do
    it "renders the new category form and builds @category" do
      get "/admin/pages/#{section.permalink}/categories/new"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('New Category')
    end
  end
end

