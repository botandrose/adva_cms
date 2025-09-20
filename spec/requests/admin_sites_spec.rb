require "rails_helper"

RSpec.describe "Admin::Sites", type: :request do
  let!(:site) { Site.find_by_host('site-with-pages.com') || Site.create!(name: 'site with pages', title: 'site with pages title', host: 'site-with-pages.com') }

  it "redirects anonymous users to login on index" do
    host! site.host
    get admin_sites_path
    expect(response).to redirect_to(login_url(return_to: admin_sites_url))
  end

  it "redirects anonymous users to login on show" do
    host! site.host
    get admin_site_path(site)
    expect(response).to redirect_to(login_url(return_to: admin_site_url(site)))
  end
end

