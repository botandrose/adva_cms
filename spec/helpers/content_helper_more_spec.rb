require "rails_helper"

RSpec.describe ContentHelper, type: :helper do

  let(:site) { Site.create!(name: 'n', title: 't', host: 'content.local') }
  let(:section) { Page.create!(site: site, title: 'p', permalink: 'p') }
  let(:user) { User.create!(first_name: 'U', email: 'user@example.com', password: 'AAbbcc1122!!', verified_at: Time.now) }

  describe "published_at_formatted" do
    it "returns Draft when not published and no date" do
      article = Article.new
      allow(article).to receive(:published?).and_return(false)
      expect(helper.published_at_formatted(article)).to eq('Draft')
    end

    it "returns future scheduling message when date is in the future" do
      article = Article.new(published_at: 2.days.from_now)
      allow(article).to receive(:published?).and_return(false)
      expect(helper.published_at_formatted(article)).to start_with('Will publish on ')
    end

    it "formats date when published" do
      article = Article.create!(site: site, section: section, title: 'a', body: 'b', author: user, published_at: 1.hour.ago, permalink: 'a1')
      expect(helper.published_at_formatted(article)).not_to include('Draft')
    end
  end

  it "page_link_path returns link body" do
    link = Link.new(body: 'http://example.com')
    expect(helper.page_link_path(section, link)).to eq('http://example.com')
  end

  describe "link_to_preview" do
    it "delegates to link_to_show with preview class" do
      article = Article.create!(site: site, section: section, title: 'a', body: 'b', author: user, published_at: 1.hour.ago, permalink: 'a2')
      allow(helper).to receive(:resource_url).and_return('/prev')
      html = helper.link_to_preview(article)
      expect(html).to include('href="/prev"')
      expect(html).to include('class="preview article"')
      expect(html).to include('>Preview<')
    end
  end

  describe "link_to_content" do
    it "uses object title by default" do
      article = Article.create!(site: site, section: section, title: 'Title', body: 'b', author: user, published_at: 1.hour.ago, permalink: 'a3')
      expect(helper).to receive(:link_to_show).with('Title', article, anything).and_return('A')
      expect(helper.link_to_content(article)).to eq('A')
    end

    it "falls back to site name for Site objects" do
      expect(helper).to receive(:link_to_show).with(site.name, site, anything).and_return('S')
      expect(helper.link_to_content(site)).to eq('S')
    end
  end

  describe "categories & tags links" do
    it "link_to_category builds persisted and non-persisted links" do
      saved = Category.create!(section: section, title: 'Saved')
      unsaved = Category.new(section: section, title: 'Unsaved')

      html1 = helper.link_to_category(section, saved)
      expect(html1).to include("/p/categories/#{saved.id}")

      html2 = helper.link_to_category(section, unsaved)
      expect(html2).to include("/p")
    end

    it "links_to_content_categories renders joined links" do
      a = Article.create!(site: site, section: section, title: 'a', body: 'b', author: user, published_at: 1.hour.ago, permalink: 'a4')
      c1 = Category.create!(section: section, title: 'C1')
      c2 = Category.create!(section: section, title: 'C2')
      a.categories << [c1, c2]

      html = helper.links_to_content_categories(a)
      expect(html).to include('in:')
      expect(html).to include("/p/categories/#{c1.id}")
      expect(html).to include("/p/categories/#{c2.id}")
    end

    it "link_to_tag builds links with and without block" do
      tag = Tag.find_or_create_by_name('blue')
      # without block
      html = helper.link_to_tag(section, tag)
      expect(html).to include('/p/tags/blue')
      expect(html).to include('>blue<')
      # with block
      html2 = helper.link_to_tag(section, tag) { 'X' }
      expect(html2).to include('/p/tags/blue')
      expect(html2).to include('>X<')
    end

    it "links_to_content_tags renders joined tag links" do
      a = Article.create!(site: site, section: section, title: 'a', body: 'b', author: user, published_at: 1.hour.ago, permalink: 'a5')
      t1 = Tag.find_or_create_by_name('red')
      t2 = Tag.find_or_create_by_name('green')
      a.tags << [t1, t2]

      html = helper.links_to_content_tags(a)
      expect(html).to include('tagged:')
      expect(html).to include('/p/tags/red')
      expect(html).to include('/p/tags/green')
    end
  end
end
