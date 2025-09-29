require "rails_helper"

RSpec.describe Content, type: :model do
  let(:site) { Site.create!(name: 'test', host: 'test.example.com') }
  let(:section) { Page.create!(site: site, title: 'Test Section') }
  let(:user) { User.create!(first_name: 'John', email: 'john@example.com', password: 'AAbbcc1122!!') }
  let(:category) { Category.create!(section: section, title: 'Test Category') }

  describe "associations" do
    it "belongs to site" do
      expect(Content.reflect_on_association(:site)).to be_a(ActiveRecord::Reflection::BelongsToReflection)
    end

    it "belongs to section" do
      association = Content.reflect_on_association(:section)
      expect(association).to be_a(ActiveRecord::Reflection::BelongsToReflection)
      expect(association.options[:touch]).to be_truthy
    end

    it "has many categorizations" do
      association = Content.reflect_on_association(:categorizations)
      expect(association).to be_a(ActiveRecord::Reflection::HasManyReflection)
      expect(association.options[:as]).to eq(:categorizable)
      expect(association.options[:dependent]).to eq(:destroy)
    end

    it "has many categories through categorizations" do
      association = Content.reflect_on_association(:categories)
      expect(association).to be_a(ActiveRecord::Reflection::ThroughReflection)
      expect(association.options[:through]).to eq(:categorizations)
    end

    it "has many activities" do
      association = Content.reflect_on_association(:activities)
      expect(association).to be_a(ActiveRecord::Reflection::HasManyReflection)
      expect(association.options[:as]).to eq(:object)
    end
  end

  describe "nested set behavior" do
    let!(:parent) { Article.create!(site: site, section: section, title: 'Parent', body: 'Parent content', author: user) }
    let!(:child) { Article.create!(site: site, section: section, title: 'Child', body: 'Child content', author: user, parent: parent) }

    it "maintains nested set structure" do
      expect(parent.children).to include(child)
      expect(child.parent).to eq(parent)
    end

    it "scopes nested set by section_id" do
      other_section = Page.create!(site: site, title: 'Other Section')
      other_content = Article.create!(site: site, section: other_section, title: 'Other', body: 'Other content', author: user)

      expect(parent.children).not_to include(other_content)
    end
  end

  describe "scopes" do
    let!(:published_content) do
      Article.create!(
        site: site,
        section: section,
        title: 'Published',
        body: 'Published content',
        author: user,
        published_at: 1.hour.ago
      )
    end

    let!(:future_content) do
      Article.create!(
        site: site,
        section: section,
        title: 'Future',
        body: 'Future content',
        author: user,
        published_at: 1.hour.from_now
      )
    end

    let!(:draft_content) do
      Article.create!(
        site: site,
        section: section,
        title: 'Draft',
        body: 'Draft content',
        author: user,
        published_at: nil
      )
    end

    describe ".published" do
      it "returns only content published in the past" do
        expect(Content.published).to include(published_content)
        expect(Content.published).not_to include(future_content)
        expect(Content.published).not_to include(draft_content)
      end
    end

    describe ".drafts" do
      it "returns only content with nil published_at" do
        expect(Content.drafts).to include(draft_content)
        expect(Content.drafts).not_to include(published_content)
        expect(Content.drafts).not_to include(future_content)
      end
    end

    describe ".unpublished" do
      it "returns drafts" do
        expect(Content.unpublished).to include(draft_content)
        expect(Content.unpublished).not_to include(published_content)
      end
    end

    describe ".by_category" do
      let!(:categorized_content) do
        content = Article.create!(site: site, section: section, title: 'Categorized', body: 'Categorized content', author: user)
        content.categories << category
        content
      end

      it "returns content in the specified category" do
        expect(Content.by_category(category)).to include(categorized_content)
        expect(Content.by_category(category)).not_to include(published_content)
      end
    end
  end

  describe "publishing behavior" do
    let(:content) { Article.new(site: site, section: section, title: 'Test', body: 'Test content', author: user) }

    describe "#published?" do
      it "returns false when published_at is nil" do
        content.published_at = nil
        expect(content.published?).to be_falsey
      end

      it "returns false when published_at is in the future" do
        content.published_at = 1.hour.from_now
        expect(content.published?).to be_falsey
      end

      it "returns true when published_at is in the past" do
        content.published_at = 1.hour.ago
        expect(content.published?).to be_truthy
      end
    end

    describe "#draft?" do
      it "returns true when published_at is nil" do
        content.published_at = nil
        expect(content.draft?).to be_truthy
      end

      it "returns false when published_at is set" do
        content.published_at = 1.hour.ago
        expect(content.draft?).to be_falsey
      end
    end

    describe "#pending?" do
      it "returns true when not published" do
        content.published_at = nil
        expect(content.pending?).to be_truthy
      end

      it "returns false when published" do
        content.published_at = 1.hour.ago
        expect(content.pending?).to be_falsey
      end
    end

    describe "#state" do
      it "returns :pending when not published" do
        content.published_at = nil
        expect(content.state).to eq(:pending)
      end

      it "returns :published when published" do
        content.published_at = 1.hour.ago
        expect(content.state).to eq(:published)
      end
    end
  end

  describe "#to_param" do
    let(:content) { Article.create!(site: site, section: section, title: 'Test Article', body: 'Test content', author: user) }

    it "returns the permalink" do
      expect(content.to_param).to eq(content.permalink)
    end
  end

  describe "#owner" do
    let(:content) { Article.create!(site: site, section: section, title: 'Test', body: 'Test content', author: user) }

    it "returns the section" do
      expect(content.owner).to eq(section)
    end
  end

  describe "#category_titles" do
    let(:content) { Article.create!(site: site, section: section, title: 'Test', body: 'Test content', author: user) }
    let!(:category1) { Category.create!(section: section, title: 'Category 1') }
    let!(:category2) { Category.create!(section: section, title: 'Category 2') }

    before do
      content.categories << [category1, category2]
    end

    it "returns an array of category titles" do
      expect(content.category_titles).to contain_exactly('Category 1', 'Category 2')
    end
  end

  describe "date helpers" do
    let(:content) do
      Article.create!(
        site: site,
        section: section,
        title: 'Test',
        body: 'Test content',
        author: user,
        published_at: Time.local(2023, 6, 15, 14, 30)
      )
    end

    describe "#published_year" do
      it "returns the first day of the published year" do
        expect(content.published_year).to eq(Time.local(2023, 1, 1))
      end
    end

    describe "#published_month" do
      it "returns the first day of the published month" do
        expect(content.published_month).to eq(Time.local(2023, 6, 1))
      end
    end

    describe "#published_at?" do
      it "returns true when published on the given date" do
        expect(content.published_at?(['2023', '6', '15'])).to be_truthy
      end

      it "returns false when not published on the given date" do
        expect(content.published_at?(['2023', '6', '16'])).to be_falsey
      end

      it "returns false when not published" do
        content.update!(published_at: nil)
        expect(content.published_at?(['2023', '6', '15'])).to be_falsey
      end
    end
  end

  describe "site assignment" do
    it "automatically sets site_id from section" do
      content = Article.new(section: section, title: 'Test', body: 'Test content', author: user)
      content.valid? # trigger validations
      expect(content.site_id).to eq(section.site_id)
    end
  end

  describe ".primary" do
    let!(:content1) { Article.create!(site: site, section: section, title: 'First', body: 'First content', author: user, published_at: 2.hours.ago) }
    let!(:content2) { Article.create!(site: site, section: section, title: 'Second', body: 'Second content', author: user, published_at: 1.hour.ago) }

    it "returns the first published content" do
      expect(section.contents.primary).to eq(content1)
    end
  end

  describe "#author_id=" do
    let(:content) { Article.new(site: site, section: section, title: 'Test', body: 'Test content') }
    let(:other_user) { User.create!(first_name: 'Jane', email: 'jane@example.com', password: 'AAbbcc1122!!') }

    it "sets the author when given a valid user id" do
      content.author_id = other_user.id
      expect(content.author).to eq(other_user)
    end

    it "does not set author when given nil" do
      content.author_id = nil
      expect(content.author).to be_nil
    end
  end

  describe "#just_published?" do
    let(:content) { Article.create!(site: site, section: section, title: 'Test', body: 'Test content', author: user) }

    it "returns true when content is published and published_at changed" do
      content.published_at = Time.current
      expect(content.just_published?).to be_truthy
    end

    it "returns false when content is not published" do
      content.published_at = nil
      expect(content.just_published?).to be_falsey
    end

    it "returns false when published but published_at has not changed" do
      content.update!(published_at: Time.current)
      content.reload
      expect(content.just_published?).to be_falsey
    end
  end

  describe "#approved_comments" do
    let(:content) { Article.create!(site: site, section: section, title: 'Test', body: 'Test content', author: user) }

    it "returns an empty array" do
      expect(content.approved_comments).to eq([])
    end
  end

  describe "#accept_comments?" do
    let(:content) { Article.create!(site: site, section: section, title: 'Test', body: 'Test content', author: user) }

    it "returns false" do
      expect(content.accept_comments?).to be_falsey
    end
  end

  describe "#owners" do
    let(:content) { Article.create!(site: site, section: section, title: 'Test', body: 'Test content', author: user) }

    it "returns an array including the owner and its owners" do
      allow(section).to receive(:owners).and_return([site])
      expect(content.owners).to include(section)
    end
  end

  describe "STI support" do
    it "can find STI classes in development mode" do
      # This tests the find_sti_class override for development
      expect(Content.find_sti_class('Article')).to eq(Article)
    end
  end

  describe "after_save callback" do
    let(:content) { Article.create!(site: site, section: section, title: 'Test', body: 'Test content', author: user) }

    it "touches associated categories" do
      content.categories << category
      expect(category).to receive(:touch)
      content.save!
    end
  end

end
