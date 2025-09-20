require "rails_helper"

RSpec.describe "Admin::Sites CRUD", type: :request do
  let!(:site) { Site.find_by_host('site-with-pages.com') || Site.create!(name: 'site with pages', title: 'site with pages title', host: 'site-with-pages.com') }

  before do
    host! site.host
    login_as_admin
    @old_multi = Site.multi_sites_enabled
    Site.multi_sites_enabled = true
  end

  after do
    Site.multi_sites_enabled = @old_multi
  end

  it "creates a site and redirects to show" do
    expect {
      post admin_sites_path, params: { site: { name: 'n', title: 't', host: 'new.local' }, section: { title: 'Home' } }
    }.to change { Site.count }.by(1)
    created = Site.find_by_host('new.local')
    expect(response).to redirect_to(admin_site_url(created))
  end

  it "updates a site and redirects to edit" do
    put admin_site_path(site), params: { site: { name: 'changed' } }
    expect(response).to redirect_to(edit_admin_site_url)
    expect(site.reload.name).to eq('changed')
  end

  it "destroys a site and redirects" do
    temp = Site.create!(name: 'del', title: 'del', host: 'del.local')
    delete admin_site_path(temp)
    expect(response).to be_redirect
    expect(Site.where(host: 'del.local')).to be_empty
  end
end
