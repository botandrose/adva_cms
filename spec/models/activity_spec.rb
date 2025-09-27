require "rails_helper"

RSpec.describe Activity, type: :model do
  let(:site) { Site.create!(name: 'test', host: 'test.example.com') }
  let(:section) { Page.create!(site: site, title: 'Test Section') }
  let(:user) { User.create!(first_name: 'John', email: 'john@example.com', password: 'AAbbcc1122!!') }
  let(:article) { Article.create!(site: site, section: section, title: 'Test Article', body: 'Test content', author: user) }

  describe "associations" do
    it "belongs to site" do
      expect(Activity.reflect_on_association(:site)).to be_a(ActiveRecord::Reflection::BelongsToReflection)
    end

    it "belongs to section" do
      expect(Activity.reflect_on_association(:section)).to be_a(ActiveRecord::Reflection::BelongsToReflection)
    end

    it "belongs to object polymorphically" do
      association = Activity.reflect_on_association(:object)
      expect(association).to be_a(ActiveRecord::Reflection::BelongsToReflection)
      expect(association.options[:polymorphic]).to be_truthy
    end
  end

  describe "validations" do
    it "validates presence of site, section, object, and author" do
      activity = Activity.new
      expect(activity).not_to be_valid
      expect(activity.errors[:site]).to include("must exist")
      expect(activity.errors[:section]).to include("must exist")
      expect(activity.errors[:object]).to include("must exist")
      expect(activity.errors[:author]).to include("can't be blank")
    end

    it "is valid with required associations" do
      activity = Activity.new(site: site, section: section, object: article, author: user)
      expect(activity).to be_valid
    end
  end

  describe "serialized attributes" do
    let(:activity) { Activity.create!(site: site, section: section, object: article, author: user) }

    it "serializes actions" do
      activity.actions = ['created', 'published']
      activity.save!
      activity.reload
      expect(activity.actions).to eq(['created', 'published'])
    end

    it "serializes object_attributes" do
      activity.object_attributes = { 'title' => 'Test', 'status' => 'published' }
      activity.save!
      activity.reload
      expect(activity.object_attributes).to eq({ 'title' => 'Test', 'status' => 'published' })
    end
  end

  describe "method_missing for object_attributes" do
    let(:activity) do
      Activity.create!(
        site: site,
        section: section,
        object: article,
        author: user,
        object_attributes: { 'custom_field' => 'test_value' }
      )
    end

    it "returns value from object_attributes when key exists" do
      expect(activity.custom_field).to eq('test_value')
    end

    it "calls super when key does not exist in object_attributes" do
      expect { activity.nonexistent_method }.to raise_error(NoMethodError)
    end
  end

  describe "#coincides_with?" do
    let!(:activity1) { Activity.create!(site: site, section: section, object: article, author: user, created_at: 1.hour.ago) }
    let!(:activity2) { Activity.create!(site: site, section: section, object: article, author: user, created_at: 30.minutes.ago) }
    let!(:activity3) { Activity.create!(site: site, section: section, object: article, author: user, created_at: 3.hours.ago) }

    it "returns true when activities are within default 1 hour delta" do
      expect(activity1.coincides_with?(activity2)).to be_truthy
    end

    it "returns false when activities are beyond default delta" do
      expect(activity1.coincides_with?(activity3)).to be_falsey
    end

    it "accepts custom delta" do
      expect(activity1.coincides_with?(activity3, 3.hours)).to be_truthy
    end
  end

  describe "#all_actions" do
    let(:activity) { Activity.create!(site: site, section: section, object: article, author: user, actions: ['main_action']) }

    before do
      sibling1 = Activity.create!(site: site, section: section, object: article, author: user, actions: ['sibling1'])
      sibling2 = Activity.create!(site: site, section: section, object: article, author: user, actions: ['sibling2'])
      activity.siblings = [sibling1, sibling2]
    end

    it "combines actions from siblings and self, removing duplicates" do
      expect(activity.all_actions).to eq(['sibling2', 'sibling1', 'main_action'])
    end
  end

  describe "#from and #to" do
    let(:activity) { Activity.create!(site: site, section: section, object: article, author: user) }

    context "with siblings" do
      let(:sibling) { Activity.create!(site: site, section: section, object: article, author: user, created_at: 1.hour.ago) }

      before { activity.siblings = [sibling] }

      it "#from returns last sibling's created_at" do
        expect(activity.from).to eq(sibling.created_at)
      end

      it "#to returns activity's created_at" do
        expect(activity.to).to eq(activity.created_at)
      end
    end

    context "without siblings" do
      it "#from returns nil" do
        expect(activity.from).to be_nil
      end

      it "#to returns activity's created_at" do
        expect(activity.to).to eq(activity.created_at)
      end
    end
  end

  describe ".find_coinciding" do
    before do
      # Create activities for the same object at different times
      Activity.create!(site: site, section: section, object: article, author: user, created_at: 1.hour.ago)
      Activity.create!(site: site, section: section, object: article, author: user, created_at: 30.minutes.ago)
    end

    it "returns activities grouped and sorted by created_at descending" do
      result = Activity.find_coinciding
      expect(result).to be_an(Array)
      expect(result.size).to eq(1) # Should be grouped
    end
  end
end