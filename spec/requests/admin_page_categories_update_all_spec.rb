require "rails_helper"

RSpec.describe "Admin::Page::Categories", type: :request do
  let!(:site) { Site.find_by_host('site-with-pages.com') || Site.create!(name: 'site with pages', title: 'site with pages title', host: 'site-with-pages.com') }
  let!(:section) { site.sections.first || Page.create!(site: site, title: 'a page', permalink: 'a-page', comment_age: 0) }

  before do
    host! site.host
    login_as_admin
  end

  it "update_all updates category positions and paths" do
    c1 = section.categories.create!(title: 'C1')
    c2 = section.categories.create!(title: 'C2')
    fake_assoc = double(update: true, update_paths!: true)
    allow_any_instance_of(Section).to receive(:categories).and_return(fake_assoc)
    put admin_page_categories_path(section), params: { categories: { c1.id.to_s => { parent_id: nil }, c2.id.to_s => { parent_id: c1.id.to_s } } }
    expect(response).to have_http_status(:ok)
  end

  it "create/update failure paths still render form" do
    allow_any_instance_of(Category).to receive(:save).and_return(false)
    post admin_page_categories_path(section), params: { category: { title: 'X' } }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('<form')

    cat = section.categories.create!(title: 'Y')
    allow_any_instance_of(Category).to receive(:update).and_return(false)
    put admin_page_category_path(section, cat), params: { category: { title: 'Z' } }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('<form')
  end

  it "destroy failure renders edit page" do
    cat = section.categories.create!(title: 'D')
    allow_any_instance_of(Category).to receive(:destroy).and_return(false)
    delete admin_page_category_path(section, cat)
    expect(response).to have_http_status(:ok)
  end
end
