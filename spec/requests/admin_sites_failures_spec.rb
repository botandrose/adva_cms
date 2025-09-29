require "rails_helper"

RSpec.describe "Admin::Sites flows", type: :request do
  let!(:site) { Site.find_by_host('site-with-pages.com') || Site.create!(name: 'site with pages', title: 'site with pages title', host: 'site-with-pages.com') }

  before do
    host! site.host
    login_as_admin
  end

  it "renders create/update/destroy failures" do
    allow_any_instance_of(Site).to receive(:save).and_return(false)
    # Avoid passing section params to keep view from receiving unpermitted parameters
    permitted = ActionController::Parameters.new(site: { name: 'N', title: 'T', host: 'h.local', email: 'a@b.co' }).permit!
    post admin_sites_path, params: permitted.to_h
    expect(response).to have_http_status(:ok)

    allow_any_instance_of(Site).to receive(:update).and_return(false)
    put admin_site_path(site), params: { site: { title: 'Z' } }
    expect(response).to have_http_status(:ok)

    allow_any_instance_of(Site).to receive(:destroy).and_return(false)
    delete admin_site_path(site)
    expect(response).to have_http_status(:ok)
  end

  it "protects single site mode" do
    allow(Site).to receive(:multi_sites_enabled).and_return(false)
    get admin_sites_path
    expect(response).to redirect_to(admin_site_url(Site.first))

    get new_admin_site_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Single-site mode')

    # Also covers create/destroy rendering branch in protect_single_site_mode
    post admin_sites_path, params: { site: { name: 'X', title: 'Y', host: 'x.local', email: 'a@b.co' }, section: { title: 'Home' } }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Single-site mode')

    delete admin_site_path(site)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Single-site mode')
  end
end
