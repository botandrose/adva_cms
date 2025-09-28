require "rails_helper"

RSpec.describe "Admin::Page::Contents", type: :request do
  let!(:site) { Site.find_by_host('site-with-pages.com') || Site.create!(name: 'site with pages', title: 'site with pages title', host: 'site-with-pages.com') }
  let!(:section) { site.sections.first || Page.create!(site: site, title: 'a page', permalink: 'a-page', comment_age: 0) }

  before do
    host! site.host
    login_as_admin
  end

  it "lists contents on index" do
    section.update!(single_article_mode: false)
    get admin_page_contents_path(section)
    expect(response).to have_http_status(:ok)
  end

  it "update_all reorders with/without parent and left" do
    author = User.create!(first_name: 'U', email: 'u5@example.com', password: 'AAbbcc1122!!', verified_at: Time.now)
    a = section.articles.create!(title: 'A', body: 'x', author: author, published_at: 1.hour.ago, permalink: 'a')
    b = section.articles.create!(title: 'B', body: 'y', author: author, published_at: 1.hour.ago, permalink: 'b')
    put admin_page_contents_path(section), params: { contents: { a.id.to_s => { parent_id: b.id.to_s, left_id: b.id.to_s } } }
    expect(response).to have_http_status(:ok)
    put admin_page_contents_path(section), params: { contents: { a.id.to_s => { parent_id: 'null', left_id: 'null' } } }
    expect(response).to have_http_status(:ok)
  end

  it "redirects in single_article_mode on index" do
    section.update!(single_article_mode: true)
    section.articles.destroy_all
    get admin_page_contents_path(section)
    expect(response).to have_http_status(:found)
    expect(response.location).to match(%r{/admin/.+/articles/new})

    article = section.articles.create!(title: 'T', body: 'B', author: User.create!(first_name: 'A', email: 'a@b.co', password: 'AAbbcc1122!!', verified_at: Time.now), published_at: 1.hour.ago, permalink: 't')
    get admin_page_contents_path(section)
    expect(response).to have_http_status(:found)
    expect(response.location).to match(%r{/admin/.+/articles/.+/edit})
  end
end
