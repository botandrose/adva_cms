require "rails_helper"

RSpec.describe "Admin::Articles CRUD", type: :request do
  let!(:site) { Site.find_by_host('site-with-pages.com') || Site.create!(name: 'site with pages', title: 'site with pages title', host: 'site-with-pages.com') }
  let!(:section) { site.sections.first || Page.create!(site: site, title: 'a page', permalink: 'a-page', comment_age: 0) }

  before do
    host! site.host
    login_as_admin
  end

  it "renders new/edit for admin" do
    get new_admin_page_article_path(section)
    expect(response.code.to_i).to satisfy { |c| [200, 302].include?(c) }
    user = User.find_by_email('admin@example.com')
    article = section.articles.create!(title: 't', body: 'b', author: user)
    get edit_admin_page_article_path(section, article)
    expect(response.code.to_i).to satisfy { |c| [200, 302].include?(c) }
  end

  it "creates an article and redirects to edit" do
    user = User.find_by_email('admin@example.com')
    expect {
      post admin_page_articles_path(section), params: { article: { title: 't', body: 'b', author_id: user.id } }
    }.to change { Article.count }.by(1)
    article = section.articles.order(:created_at).last
    expect(response).to redirect_to(edit_admin_page_article_url(section, article))
  end

  it "updates an article and redirects to edit" do
    user = User.find_by_email('admin@example.com')
    article = section.articles.create!(title: 't', body: 'b', author: user)
    put admin_page_article_path(section, article), params: { article: { title: 't2', updated_at: article.updated_at.to_s, author_id: user.id } }
    expect(response).to redirect_to(edit_admin_page_article_url(section, article))
    expect(article.reload.title).to eq('t2')
  end

  it "destroys an article and redirects to contents" do
    user = User.find_by_email('admin@example.com')
    article = section.articles.create!(title: 'td', body: 'bd', author: user)
    delete admin_page_article_path(section, article)
    # Controller redirects to [:admin, @section, :contents] which resolves to /admin/pages/:permalink/contents
    expect(response).to redirect_to("/admin/pages/#{section.permalink}/contents")
    expect(section.articles.where(permalink: article.permalink)).to be_empty
  end
end
