require "rails_helper"

RSpec.describe "Unpublished sections", type: :request do
  let!(:site) { Site.find_by_host('site-with-pages.com') || Site.create!(name: 'site with pages', title: 'site with pages title', host: 'site-with-pages.com') }

  it "returns 404 for anonymous when section unpublished" do
    section = Page.create!(site: site, title: 'unpub', permalink: 'unpub')
    section.update!(published_at: nil)

    host! site.host
    get page_path(section)
    expect(response.status).to eq(404)
  end
end

