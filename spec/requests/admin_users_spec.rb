require "rails_helper"

RSpec.describe "Admin::Users", type: :request do
  let!(:site) { Site.find_by_host('site-with-pages.com') || Site.create!(name: 'site with pages', title: 'site with pages title', host: 'site-with-pages.com') }

  it "redirects anonymous users to login on index" do
    host! site.host
    get admin_users_path
    expect(response).to redirect_to(login_url(return_to: admin_users_url))
  end
end

