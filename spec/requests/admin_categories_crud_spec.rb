require "rails_helper"

RSpec.describe "Admin::Categories CRUD", type: :request do
  let!(:site) { Site.find_by_host('site-with-pages.com') || Site.create!(name: 'site with pages', title: 'site with pages title', host: 'site-with-pages.com') }
  let!(:section) { site.sections.first || Page.create!(site: site, title: 'a page', permalink: 'a-page', comment_age: 0) }

  before do
    host! site.host
    login_as_admin
  end

  it "creates a category and redirects to index" do
    expect {
      post admin_section_categories_path(section), params: { category: { title: 'cat' } }
    }.to change { Category.count }.by(1)
    expect(response).to redirect_to("/admin/pages/#{section.permalink}/categories")
  end

  it "updates a category and redirects to index" do
    cat = section.categories.create!(title: 'old')
    put admin_section_category_path(section, cat), params: { category: { title: 'new' } }
    expect(response).to redirect_to("/admin/pages/#{section.permalink}/categories")
    expect(cat.reload.title).to eq('new')
  end

  it "destroys a category and redirects to index" do
    cat = section.categories.create!(title: 'del')
    delete admin_section_category_path(section, cat)
    expect(response).to redirect_to("/admin/pages/#{section.permalink}/categories")
    expect(section.categories.where(permalink: cat.permalink)).to be_empty
  end
end
