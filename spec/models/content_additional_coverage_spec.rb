require "rails_helper"

RSpec.describe Content, type: :model do
  let(:site) { Site.create!(name: 'test', host: 'test.example.com') }
  let(:section) { Page.create!(site: site, title: 'Test Section') }
  let(:user) { User.create!(first_name: 'John', email: 'john@example.com', password: 'AAbbcc1122!!') }
  let(:article) { Article.create!(site: site, section: section, title: 'Test Article', body: 'Test content', author: user) }

  describe "#published_year" do
    it "returns the year of the published_at date" do
      article.update!(published_at: Time.parse("2023-05-15 10:00:00"))
      expect(article.published_year).to eq(Time.local(2023, 1, 1))
    end
  end

  describe "#published_month" do
    it "returns the first day of the published month" do
      article.update!(published_at: Time.parse("2023-05-15 10:00:00"))
      expect(article.published_month).to eq(Time.local(2023, 5, 1))
    end
  end

  describe "#published_at?" do
    it "returns true when published and date matches" do
      article.update!(published_at: Time.parse("2023-05-15 10:00:00"))
      expect(article.published_at?(['2023', '5', '15'])).to be_truthy
    end

    it "returns false when not published" do
      article.update!(published_at: nil)
      expect(article.published_at?(['2023', '5', '15'])).to be_falsy
    end

    it "returns false when date doesn't match" do
      article.update!(published_at: Time.parse("2023-05-15 10:00:00"))
      expect(article.published_at?(['2023', '5', '16'])).to be_falsy
    end
  end

  describe "#just_published?" do
    it "returns true when published and published_at changed" do
      article.update!(published_at: nil)
      article.published_at = 1.hour.ago
      expect(article.just_published?).to be_truthy
    end

    it "returns false when not published" do
      article.update!(published_at: nil)
      expect(article.just_published?).to be_falsy
    end

    it "returns false when published but published_at didn't change" do
      article.update!(published_at: 1.hour.ago)
      article.reload
      expect(article.just_published?).to be_falsy
    end
  end

  describe "#category_titles" do
    let(:category1) { Category.create!(section: section, title: 'Category 1') }
    let(:category2) { Category.create!(section: section, title: 'Category 2') }

    it "returns array of category titles" do
      article.categories = [category1, category2]
      expect(article.category_titles).to contain_exactly('Category 1', 'Category 2')
    end

    it "returns empty array when no categories" do
      expect(article.category_titles).to eq([])
    end
  end

  describe "#author_id=" do
    let(:other_user) { User.create!(first_name: 'Jane', email: 'jane@example.com', password: 'AAbbcc1122!!') }

    it "sets the author by id" do
      article.author_id = other_user.id
      expect(article.author).to eq(other_user)
    end

    it "does nothing when author_id is nil" do
      original_author = article.author
      article.author_id = nil
      expect(article.author).to eq(original_author)
    end
  end

  describe "#published_at=" do
    context "when draft is set to 1" do
      it "sets published_at to nil" do
        article.draft = '1'
        article.published_at = Time.current
        expect(article.published_at).to be_nil
      end
    end

    context "when draft is not set to 1" do
      it "sets published_at to the given value" do
        time = Time.current
        article.draft = '0'
        article.published_at = time
        expect(article.published_at.to_i).to eq(time.to_i)
      end
    end
  end

  describe ".primary" do
    before { Content.delete_all }

    let!(:older_article) { Article.create!(site: site, section: section, title: 'Older', body: 'content', author: user, published_at: 2.days.ago) }
    let!(:newer_article) { Article.create!(site: site, section: section, title: 'Newer', body: 'content', author: user, published_at: 1.day.ago) }
    let!(:draft_article) { Article.create!(site: site, section: section, title: 'Draft', body: 'content', author: user, published_at: nil) }

    it "returns the first published article from scope" do
      expect(Article.primary).to eq(older_article)
    end

    it "does not return draft articles" do
      older_article.destroy
      newer_article.destroy
      expect(Article.primary).to be_nil
    end
  end

  describe "#owners" do
    it "returns section owners including the section itself" do
      expect(article.owners).to include(section)
    end
  end

  describe "#owner" do
    it "returns the section" do
      expect(article.owner).to eq(section)
    end
  end

  describe "#to_param" do
    it "returns the permalink" do
      article.permalink = 'test-article-permalink'
      expect(article.to_param).to eq('test-article-permalink')
    end
  end

  describe "#accept_comments?" do
    it "returns false by default" do
      expect(article.accept_comments?).to be_falsy
    end
  end

  describe "#approved_comments" do
    it "returns empty array by default" do
      expect(article.approved_comments).to eq([])
    end
  end

  describe "set_site callback" do
    it "sets site_id from section" do
      new_article = Content.new(section: section, title: 'New Article', author: user)
      new_article.valid?
      expect(new_article.site_id).to eq(section.site_id)
    end

    it "does not set site_id when section is nil" do
      new_article = Content.new(title: 'New Article', author: user)
      new_article.valid?
      expect(new_article.site_id).to be_nil
    end
  end

  describe "categories touch on save" do
    let(:category) { Category.create!(section: section, title: 'Test Category') }

    it "touches associated categories when saved" do
      article.categories << category
      original_updated_at = category.updated_at

      sleep 0.1
      article.update!(title: 'Updated Title')
      expect(category.reload.updated_at).to be > original_updated_at
    end
  end
end