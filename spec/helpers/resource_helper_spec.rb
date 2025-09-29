require "rails_helper"

RSpec.describe ResourceHelper, type: :helper do
  include ResourceHelper

  ResourceDummy = Struct.new(:id)

  it "normalizes resource type for Section and symbols" do
    expect(normalize_resource_type(:show, nil, Section.new)).to eq('section')
    expect(normalize_resource_type(:index, :article, ResourceDummy.new(1))).to eq('articles')
  end

  it "composes resource url method" do
    expect(resource_url_method(:admin, :edit, 'article', only_path: true)).to eq('edit_admin_article_path')
    expect(resource_url_method(nil, :show, 'site', only_path: false)).to eq('site_url')
  end

  it "builds link id" do
    rec = ResourceDummy.new(42)
    expect(resource_link_id(:edit, 'article', rec)).to eq('edit_article')
    expect(resource_link_id(:index, 'articles', rec)).to eq('index_articles')
  end

  it "builds delete options with default confirm" do
    expect(resource_delete_options('article', {})).to eq({ data: { confirm: 'Are you sure you want to delete this articles?' }, method: :delete })
  end

  it "normalize_resource_link_options populates defaults and id" do
    site = Site.create!(name: 'n', title: 't', host: 'opts.local')
    section = Page.create!(site: site, title: 'p', permalink: 'p')
    user = User.create!(first_name: 'U', email: 'u3@example.com', password: 'AAbbcc1122!!', verified_at: Time.now)
    article = Article.create!(site: site, section: section, title: 'a', body: 'b', author: user, published_at: 1.hour.ago, permalink: 'a2')
    opts = normalize_resource_link_options({}, :edit, 'article', article)
    expect(opts[:class]).to eq('edit article')
    expect(opts[:title]).to eq('Edit')
    expect(opts[:id]).to eq("edit_article_#{article.id}")
  end

  it "collects resource owners via owners chain" do
    site = Site.create!(name: 'n', title: 't', host: 'owners.local')
    section = Page.create!(site: site, title: 'p', permalink: 'p')
    user = User.create!(first_name: 'U', email: 'u2@example.com', password: 'AAbbcc1122!!', verified_at: Time.now)
    article = Article.create!(site: site, section: section, title: 'a', body: 'b', author: user, published_at: 1.hour.ago, permalink: 'a')
    expect(resource_owners(article)).to eq([site, section, article])
  end

  it "normalizes resource link text with symbol via t()" do
    allow(self).to receive(:t).with(:edit_label).and_return('Translated Edit')
    text = normalize_resource_link_text(:edit_label, :edit, 'article')
    expect(text).to eq('Translated Edit')
  end

  it "resource_url_namespace prefers explicit option and deletes it" do
    opts = { namespace: :admin, only_path: true }
    ns = resource_url_namespace(opts)
    expect(ns).to eq(:admin)
    expect(opts).not_to have_key(:namespace)
  end

  it "current_controller_namespace derives from controller_path" do
    allow(self).to receive(:controller_path).and_return('admin/pages')
    expect(current_controller_namespace).to eq('admin')
  end

  describe "#resource_owners" do
    it "returns empty array for nil resource" do
      expect(resource_owners(nil)).to eq([])
    end

    it "returns empty array for symbol resource" do
      expect(resource_owners(:some_symbol)).to eq([])
    end

    it "includes section when resource responds to section" do
      site = Site.create!(name: 'test', title: 't', host: 'section.local')
      section = Page.create!(site: site, title: 'Section', permalink: 's')
      resource = double("Resource", section: section)
      allow(resource).to receive(:respond_to?).with(:owners).and_return(false)
      allow(resource).to receive(:respond_to?).with(:section).and_return(true)
      allow(resource).to receive(:respond_to?).with(:owner).and_return(false)
      expect(resource_owners(resource)).to include(section, resource)
    end

    it "includes owner when resource responds to owner but not section" do
      owner = double("Owner")
      resource = double("Resource", owner: owner)
      allow(resource).to receive(:respond_to?).with(:owners).and_return(false)
      allow(resource).to receive(:respond_to?).with(:section).and_return(false)
      allow(resource).to receive(:respond_to?).with(:owner).and_return(true)
      expect(resource_owners(resource)).to include(owner, resource)
    end

    it "just includes resource when no section or owner" do
      resource = double("Resource")
      allow(resource).to receive(:respond_to?).with(:owners).and_return(false)
      allow(resource).to receive(:respond_to?).with(:section).and_return(false)
      allow(resource).to receive(:respond_to?).with(:owner).and_return(false)
      expect(resource_owners(resource)).to eq([resource])
    end
  end
end
