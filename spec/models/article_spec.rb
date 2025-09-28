require "rails_helper"

RSpec.describe Article, type: :model do
  # Define Blog STI type used by Article#full_permalink
  class Blog < Page; end
  let(:site) { Site.create!(name: 'basic', title: 'basic', host: 'basic.local') }
  let(:page) { Page.create!(site: site, title: 'page', permalink: 'page') }
  let(:user) { User.create!(first_name: 'user', email: 'user@ex.com', password: 'AAbbcc1122!!', verified_at: Time.now) }

  it "validates presence of title and body" do
    a = Article.new(site: site, section: page, author: user)
    expect(a).not_to be_valid
    a.title = 'Hello'
    a.body = 'World'
    expect(a).to be_valid
  end

  it "validates permalink uniqueness scoped to section" do
    Article.create!(site: site, section: page, title: 'a1', body: 'b', author: user, published_at: 1.hour.ago, permalink: 'dup')
    dup = Article.new(site: site, section: page, title: 'a2', body: 'b', author: user, published_at: 1.hour.ago, permalink: 'dup')
    expect(dup).not_to be_valid

    other_section = Page.create!(site: site, title: 'other', permalink: 'other')
    ok = Article.new(site: site, section: other_section, title: 'a3', body: 'b', author: user, published_at: 1.hour.ago, permalink: 'dup')
    expect(ok).to be_valid
  end

  it "class locale returns en" do
    expect(Article.locale).to eq('en')
  end

  it "#primary? matches section primary article" do
    a1 = Article.create!(site: site, section: page, title: 'A1', body: 'b', author: user, published_at: 3.hours.ago, permalink: 'a1')
    a2 = Article.create!(site: site, section: page, title: 'A2', body: 'b', author: user, published_at: 2.hours.ago, permalink: 'a2')
    expect(a1.primary?).to eq(page.articles.primary == a1)
    expect(a2.primary?).to eq(page.articles.primary == a2)
  end

  it "previous/next navigate by published_at within section" do
    older   = Article.create!(site: site, section: page, title: 'old', body: 'b', author: user, published_at: 3.days.ago, permalink: 'old')
    middle  = Article.create!(site: site, section: page, title: 'mid', body: 'b', author: user, published_at: 2.days.ago, permalink: 'mid')
    newer   = Article.create!(site: site, section: page, title: 'new', body: 'b', author: user, published_at: 1.day.ago,  permalink: 'new')

    expect(middle.previous).to eq(older)
    expect(middle.next).to eq(newer)
    expect(older.previous).to be_nil
    expect(newer.next).to be_nil
  end

  it "has_excerpt? detects empty fckeditor excerpt and presence" do
    a = Article.new
    expect(a.has_excerpt?).to be false
    a.excerpt = "<p>&#160;</p>"
    expect(a.has_excerpt?).to be false
    a.excerpt = "Something"
    expect(a.has_excerpt?).to be true
  end

  it "full_permalink raises for non-blog sections" do
    a = Article.create!(site: site, section: page, title: 't', body: 'b', author: user, published_at: Time.current, permalink: 'p')
    expect { a.full_permalink }.to raise_error(/non-blog section/)
  end

  it "full_permalink returns date components for blog sections" do
    class Blog < Page; end
    blog = Blog.create!(site: site, title: 'blog', permalink: 'blog')
    published_at = Time.zone.local(2021, 5, 6, 10, 0, 0)
    a = Article.create!(site: site, section: blog, title: 't', body: 'b', author: user, published_at: published_at, permalink: 'p')
    fp = a.full_permalink
    expect(fp[:permalink]).to eq('p')
    expect(fp[:year]).to eq(2021)
    expect(fp[:month]).to eq(5)
    expect(fp[:day]).to eq(6)
  end
end
