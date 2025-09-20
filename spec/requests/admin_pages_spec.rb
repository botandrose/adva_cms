require "rails_helper"

RSpec.describe "Admin::Pages", type: :request do
  let!(:site) { Site.find_by_host('site-with-pages.com') || Site.create!(name: 'site with pages', title: 'site with pages title', host: 'site-with-pages.com') }
  let!(:section) { site.sections.first || Page.create!(site: site, title: 'a page', permalink: 'a-page', comment_age: 0) }

  it "redirects anonymous users to login on index" do
    host! site.host
    get "/admin/pages"
    expect(response).to redirect_to(login_url(return_to: admin_pages_url))
  end
end

