require "rails_helper"

RSpec.describe "Admin::Page::Articles extra coverage", type: :request do
  let!(:site) { Site.find_by_host('art.local') || Site.create!(name: 'art', title: 'art', host: 'art.local') }
  let!(:section) { site.sections.first || Page.create!(site: site, title: 'a page', permalink: 'a-page', comment_age: 0) }

  before do
    host! site.host
    login_as_admin
  end

  it "index redirects to contents" do
    section.update!(single_article_mode: false)
    get admin_page_articles_path(section)
    expect(response).to redirect_to(admin_page_contents_path(section))
  end

  it "redirects to new when single_article_mode with no articles" do
    section.update!(single_article_mode: true)
    section.articles.destroy_all
    get admin_page_articles_path(section)
    expect(response).to have_http_status(:found)
    expect(response.location).to match(%r{/admin/.+/articles/new})
    # Optional: ensure title param is passed
    expect(URI.parse(response.location).query).to include("article%5Btitle%5D=")
  end

  it "redirects to edit when single_article_mode with an article" do
    section.update!(single_article_mode: true)
    user = User.find_by_email('admin@example.com')
    article = section.articles.create!(title: 'Existing', body: 'b', author: user, permalink: 'existing')
    get admin_page_articles_path(section)
    expect(response).to have_http_status(:found)
    expect(response.location).to match(%r{/admin/.+/articles/#{article.to_param}/edit})
  end

  it "show renders" do
    user = User.find_by_email('admin@example.com')
    article = section.articles.create!(title: 't', body: 'b', author: user, permalink: 't')
    get admin_page_article_path(section, article)
    expect(response).to have_http_status(:ok)
  end

  it "update optimistic lock conflict renders edit" do
    user = User.find_by_email('admin@example.com')
    article = section.articles.create!(title: 't', body: 'b', author: user, permalink: 'lock')
    # send mismatching updated_at to trigger conflict
    put admin_page_article_path(section, article), params: { article: { title: 't2', updated_at: (article.updated_at - 1.day).to_s } }
    expect(response).to have_http_status(:ok)
  end

  it "create/update/destroy failure paths render forms" do
    allow_any_instance_of(Article).to receive(:save).and_return(false)
    post admin_page_articles_path(section), params: { article: { title: 'b', body: 'x' } }
    expect(response).to have_http_status(:ok)

    user = User.find_by_email('admin@example.com')
    article = section.articles.create!(title: 't', body: 'b', author: user, permalink: 'f')
    allow_any_instance_of(Article).to receive(:update).and_return(false)
    put admin_page_article_path(section, article), params: { article: { title: 'z', updated_at: article.updated_at.to_s } }
    expect(response).to have_http_status(:ok)

    allow_any_instance_of(Article).to receive(:destroy).and_return(false)
    delete admin_page_article_path(section, article)
    expect(response).to have_http_status(:ok)
  end
end
