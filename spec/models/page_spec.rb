require "rails_helper"

RSpec.describe Page, type: :model do
  let(:site) { Site.create!(name: 'test', host: 'test.example.com') }
  let(:user) { User.create!(first_name: 'John', email: 'john@example.com', password: 'AAbbcc1122!!') }

  describe "inheritance" do
    it "inherits from Section" do
      expect(Page.superclass).to eq(Section)
    end
  end

  describe "associations" do
    it "has many articles" do
      association = Page.reflect_on_association(:articles)
      expect(association).to be_a(ActiveRecord::Reflection::HasManyReflection)
      expect(association.options[:dependent]).to eq(:destroy)
      expect(association.options[:foreign_key]).to eq(:section_id)
    end

    it "has many links" do
      association = Page.reflect_on_association(:links)
      expect(association).to be_a(ActiveRecord::Reflection::HasManyReflection)
      expect(association.options[:dependent]).to eq(:destroy)
      expect(association.options[:foreign_key]).to eq(:section_id)
    end
  end

  describe ".content_types" do
    it "returns Article and Link content types" do
      expect(Page.content_types).to eq(%w(Article Link))
    end
  end

  describe "single article mode" do
    let(:page) { Page.create!(site: site, title: 'Test Page') }
    let!(:article) do
      Article.create!(
        site: site,
        section: page,
        title: 'Test Article',
        body: 'Test content',
        author: user,
        published_at: 1.hour.ago
      )
    end

    context "when single_article_mode is enabled (default)" do
      before do
        page.single_article_mode = true
      end

      describe "#published_at" do
        it "returns the first content's published_at when content exists" do
          expect(page.published_at).to be_present
          expect(page.published_at).to be_a(Time)
        end

        it "returns super when no contents" do
          page.articles.destroy_all
          page.reload
          expect(page.published_at).to eq(page[:published_at])
        end
      end

      describe "#published_at=" do
        it "updates the first content's published_at when content exists" do
          new_time = 2.hours.ago
          expect { page.published_at = new_time }.not_to raise_error
        end

        it "calls super when no contents" do
          page.articles.destroy_all
          page.reload
          new_time = 2.hours.ago
          page.published_at = new_time
          expect(page[:published_at].to_i).to eq(new_time.to_i)
        end
      end

      describe "#published?" do
        context "when page is the root section" do
          before do
            allow(page.site.sections).to receive(:root).and_return(page)
          end

          it "returns true" do
            expect(page.published?).to be_truthy
          end
        end

        context "when page has published content" do
          it "returns true" do
            expect(page.published?).to be_truthy
          end
        end

        context "when page has no content" do
          before do
            page.articles.destroy_all
            page.reload
            # Ensure this page is not the root section
            allow(page.site.sections).to receive(:root).and_return(double('root_section'))
          end

          it "returns false" do
            expect(page.published?).to be_falsey
          end
        end

        context "when page has unpublished content" do
          before do
            article.update!(published_at: nil)
            # Ensure this page is not the root section
            allow(page.site.sections).to receive(:root).and_return(double('root_section'))
          end

          it "returns false" do
            expect(page.published?).to be_falsey
          end
        end

        context "when checking parents and ancestors are unpublished" do
          let(:parent_page) { Page.create!(site: site, title: 'Parent Page', published_at: nil) }
          let(:child_page) { Page.create!(site: site, title: 'Child Page', parent: parent_page) }

          before do
            Article.create!(
              site: site,
              section: child_page,
              title: 'Child Article',
              body: 'Child content',
              author: user,
              published_at: 1.hour.ago
            )
          end

          it "returns false when ancestors are not published" do
            expect(child_page.published?(true)).to be_falsey
          end
        end
      end
    end

    context "when single_article_mode is disabled" do
      before do
        page.single_article_mode = false
      end

      describe "#published_at" do
        it "returns the page's own published_at" do
          page_time = 3.hours.ago
          page.update!(published_at: page_time)
          expect(page.published_at.to_i).to eq(page_time.to_i)
        end
      end

      describe "#published_at=" do
        it "sets the page's own published_at" do
          new_time = 2.hours.ago
          page.published_at = new_time
          expect(page[:published_at].to_i).to eq(new_time.to_i)
        end
      end

      describe "#published?" do
        it "calls super" do
          page_time = 1.hour.ago
          page.update!(published_at: page_time)
          expect(page.published?).to be_truthy
        end
      end
    end
  end

  describe "content ordering" do
    let(:page) { Page.create!(site: site, title: 'Test Page') }

    it "orders articles by lft" do
      article1 = Article.create!(site: site, section: page, title: 'Article 1', body: 'Article 1 content', author: user)
      article2 = Article.create!(site: site, section: page, title: 'Article 2', body: 'Article 2 content', author: user)

      # The nested set should automatically assign lft/rgt values in order
      expect(page.articles.order(:lft)).to eq([article1, article2])
    end

    it "orders links by lft" do
      link1 = Link.create!(site: site, section: page, title: 'Link 1', body: 'http://example.com', author: user)

      expect(page.links.order(:lft)).to eq([link1])
    end
  end
end