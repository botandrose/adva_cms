require "rails_helper"

RSpec.describe Link, type: :model do
  let(:site) { Site.create!(name: 'test', host: 'test.example.com') }
  let(:section) { Page.create!(site: site, title: 'Test Section') }
  let(:user) { User.create!(first_name: 'John', email: 'john@example.com', password: 'AAbbcc1122!!') }

  describe "inheritance" do
    it "inherits from Content" do
      expect(Link.superclass).to eq(Content)
    end
  end

  describe "validations" do
    it "validates presence of title" do
      link = Link.new(section: section, site: site)
      expect(link).not_to be_valid
      expect(link.errors[:title]).to include("can't be blank")
    end

    it "validates presence of body" do
      link = Link.new(section: section, site: site, title: 'Test Link')
      expect(link).not_to be_valid
      expect(link.errors[:body]).to include("can't be blank")
    end

    it "is valid with title and body" do
      link = Link.new(section: section, site: site, title: 'Test Link', body: 'http://example.com', author: user)
      expect(link).to be_valid
    end
  end

  describe "content behavior" do
    let(:link) { Link.create!(section: section, site: site, title: 'Test Link', body: 'http://example.com', author: user) }

    it "inherits Content functionality" do
      expect(link).to respond_to(:published?)
      expect(link).to respond_to(:draft?)
      expect(link).to respond_to(:permalink)
    end

    it "can be published" do
      link.update!(published_at: 1.hour.ago)
      expect(link.published?).to be_truthy
    end

    it "can have categories" do
      category = Category.create!(section: section, title: 'Test Category')
      link.categories << category
      expect(link.categories).to include(category)
    end
  end
end