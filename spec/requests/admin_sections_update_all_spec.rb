require "rails_helper"

RSpec.describe "Admin::Sections update_all", type: :request do
  let!(:site) { Site.find_by_host('site-with-pages.com') || Site.create!(name: 'site with pages', title: 'site with pages title', host: 'site-with-pages.com') }
  let!(:root) { Page.create!(site: site, title: 'root', permalink: 'root') }
  let!(:child) { Page.create!(site: site, title: 'child', permalink: 'child') }

  before do
    host! site.host
    login_as_admin
  end

  it "reorders with parent and left sibling present" do
    params = {
      sections: {
        child.id.to_s => { parent_id: root.id.to_s, left_id: root.id.to_s }
      }
    }
    put admin_sections_path, params: params
    expect(response).to have_http_status(:ok)
  end

  it "moves to root when parent is null and handles left_id null via normalization" do
    params = { sections: { child.id.to_s => { parent_id: 'null', left_id: 'null' } } }
    put admin_sections_path, params: params
    expect(response).to have_http_status(:ok)
  end
end

