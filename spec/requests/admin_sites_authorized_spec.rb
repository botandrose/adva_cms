require "rails_helper"

RSpec.describe "Admin::Sites (authorized)", type: :request do
  let!(:site) { Site.find_by_host('site-with-pages.com') || Site.create!(name: 'site with pages', title: 'site with pages title', host: 'site-with-pages.com') }

  it "renders index for admin" do
    host! site.host
    login_as_admin
    get admin_sites_path
    expect(response).to have_http_status(:ok).or redirect_to(/admin\/.+/)
  end
end

