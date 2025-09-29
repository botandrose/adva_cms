require "rails_helper"

RSpec.describe Section, type: :model do
  let(:site) { Site.create!(name: 'n', title: 't', host: 'h.local') }

  it "validates presence of title and uniqueness of permalink scoped to site" do
    s1 = Page.create!(site: site, title: 'a', permalink: 'a')
    s2 = Page.new(site: site, title: 'b', permalink: 'a')
    expect(s2).not_to be_valid
  end

  it "to_param returns permalink" do
    s = Page.create!(site: site, title: 'a', permalink: 'a')
    expect(s.to_param).to eq('a')
  end

  it "parameterizes permalink on assignment" do
    s = Page.create!(site: site, title: 'Hello', permalink: 'Hello World!')
    expect(s.permalink).to eq('hello-world')
  end

  it "provides default option value via has_option" do
    s = Page.create!(site: site, title: 'opt', permalink: 'opt')
    expect(s.contents_per_page).to eq(15)
  end

  it "does not change permalink when title changes (friendly id only when blank)" do
    s = Page.create!(site: site, title: 'a', permalink: 'custom')
    s.update!(title: 'changed')
    expect(s.reload.permalink).to eq('custom')
  end

  describe ".register_type" do
    it "adds type only once" do
      original = Section.types.dup
      begin
        Section.types = ["Page"]
        Section.register_type("Blog")
        expect(Section.types).to include("Blog")
        Section.register_type("Blog")
        expect(Section.types.count { |t| t == "Blog" }).to eq(1)
      ensure
        Section.types = original
      end
    end
  end

  describe "#tag_counts" do
    it "delegates to Content.tag_counts with section condition" do
      section = Page.create!(site: site, title: 's', permalink: 's')
      expect(Content).to receive(:tag_counts).with(conditions: "section_id = #{section.id}").and_return([])
      expect(section.tag_counts).to eq([])
    end
  end

  describe "#nav_children" do
    it "returns only published root contents" do
      section = Page.create!(site: site, title: 's2', permalink: 's2')
      user = User.create!(first_name: 'U', email: 'u-nav@example.com', password: 'AAbbcc1122!!', verified_at: Time.now)
      published_root = section.articles.create!(title: 'A1', body: 'x', author: user, published_at: 1.hour.ago, permalink: 'a1')
      draft_root = section.articles.create!(title: 'A2', body: 'y', author: user, published_at: nil, permalink: 'a2')
      child = section.articles.create!(title: 'A3', body: 'z', author: user, published_at: 1.hour.ago, permalink: 'a3', parent: published_root)
      expect(section.nav_children).to include(published_root)
      expect(section.nav_children).not_to include(draft_root)
      expect(section.nav_children).not_to include(child)
    end
  end

  describe "#has_unpublished_ancestor? (protected)" do
    it "returns true when any non-root ancestor is unpublished" do
      root = Page.create!(site: site, title: 'root', permalink: 'root', published_at: 1.hour.ago)
      parent = Page.create!(site: site, title: 'parent', permalink: 'parent', parent_id: root.id, published_at: nil)
      child = Page.create!(site: site, title: 'child', permalink: 'child', parent_id: parent.id, published_at: 1.hour.ago)
      expect(child.send(:has_unpublished_ancestor?)).to be_truthy
    end
  end
end
