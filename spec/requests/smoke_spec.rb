require "rails_helper"

RSpec.describe "Smoke", type: :request do
  let!(:site) { Site.find_by_host('site-with-pages.com') || Site.create!(name: 'site with pages', title: 'site with pages title', host: 'site-with-pages.com') }

  it "renders root index" do
    host! site.host
    get "/"
    expect(response).to have_http_status(:ok)
  end
end

