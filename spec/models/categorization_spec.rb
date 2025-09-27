require "rails_helper"

RSpec.describe Categorization, type: :model do
  let(:site) { Site.create!(name: 'test', host: 'test.example.com') }
  let(:section) { Page.create!(site: site, title: 'Test Section') }
  let(:category) { Category.create!(section: section, title: 'Test Category') }
  let(:user) { User.create!(first_name: 'John', email: 'john@example.com', password: 'AAbbcc1122!!') }
  let(:article) { Article.create!(site: site, section: section, title: 'Test Article', body: 'Test content', author: user) }

  describe "associations" do
    it "belongs to categorizable polymorphically" do
      association = Categorization.reflect_on_association(:categorizable)
      expect(association).to be_a(ActiveRecord::Reflection::BelongsToReflection)
      expect(association.options[:polymorphic]).to be_truthy
      expect(association.options[:touch]).to be_truthy
    end

    it "belongs to category" do
      association = Categorization.reflect_on_association(:category)
      expect(association).to be_a(ActiveRecord::Reflection::BelongsToReflection)
      expect(association.options[:touch]).to be_truthy
    end
  end

  describe "creation" do
    it "can be created with valid category and categorizable" do
      categorization = Categorization.new(category: category, categorizable: article)
      expect(categorization).to be_valid
    end

    it "links content to categories" do
      categorization = Categorization.create!(category: category, categorizable: article)
      expect(categorization.category).to eq(category)
      expect(categorization.categorizable).to eq(article)
    end
  end

  describe "touch behavior" do
    let!(:categorization) { Categorization.create!(category: category, categorizable: article) }

    it "touches the categorizable when updated" do
      original_time = article.updated_at
      sleep(0.1)
      categorization.touch
      article.reload
      expect(article.updated_at).to be > original_time
    end

    it "touches the category when updated" do
      original_time = category.updated_at
      sleep(0.1)
      categorization.touch
      category.reload
      expect(category.updated_at).to be > original_time
    end
  end

  describe "polymorphic relationships" do
    it "can link to different types of content" do
      link = Link.create!(site: site, section: section, title: 'Test Link', body: 'http://example.com', author: user)

      article_categorization = Categorization.create!(category: category, categorizable: article)
      link_categorization = Categorization.create!(category: category, categorizable: link)

      expect(article_categorization.categorizable_type).to eq('Content')
      expect(link_categorization.categorizable_type).to eq('Content')
      expect(article_categorization.categorizable).to be_a(Article)
      expect(link_categorization.categorizable).to be_a(Link)
    end
  end
end