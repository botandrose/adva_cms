require "rails_helper"

RSpec.describe "Page Articles", type: :request do
  let!(:site) { Site.find_by_host('site-with-pages.com') || Site.create!(name: 'site with pages', title: 'site with pages title', host: 'site-with-pages.com') }
  let!(:section) { Site.find_by_host('site-with-pages.com').sections.find_by(permalink: 'a-page') || Page.create!(site: site, title: 'a page', permalink: 'a-page', comment_age: 0) }
  let!(:user) { User.find_by_email('a-user@example.com') || User.create!(first_name: 'a user', email: 'a-user@example.com', password: 'AAbbcc1122!!', verified_at: Time.now) }
  let!(:article) { section.articles.first || Article.create!(site: site, section: section, title: 'a page article', body: 'body', author: user, published_at: Time.parse('2008-01-01 12:00:00')) }

  it "renders section index" do
    host! site.host
    get page_path(section)
    expect(response).to have_http_status(:ok)
  end

  it "renders article show" do
    host! site.host
    get page_article_path(section, article.permalink)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(article.title)
  end
end

