require "rails_helper"

RSpec.describe Membership, type: :model do
  let(:site) { Site.create!(name: 'test', host: 'test.example.com') }
  let(:user) { User.create!(first_name: 'John', email: 'john@example.com', password: 'AAbbcc1122!!') }

  describe "associations" do
    it "belongs to site" do
      expect(Membership.reflect_on_association(:site)).to be_a(ActiveRecord::Reflection::BelongsToReflection)
    end

    it "belongs to user" do
      expect(Membership.reflect_on_association(:user)).to be_a(ActiveRecord::Reflection::BelongsToReflection)
    end
  end

  describe "validations" do
    it "validates uniqueness of site_id scoped to user_id" do
      Membership.create!(site: site, user: user)
      duplicate = Membership.new(site: site, user: user)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:site_id]).to include("has already been taken")
    end

    it "allows same user to have memberships in different sites" do
      other_site = Site.create!(name: 'other', host: 'other.example.com')

      membership1 = Membership.create!(site: site, user: user)
      membership2 = Membership.new(site: other_site, user: user)

      expect(membership1).to be_valid
      expect(membership2).to be_valid
    end

    it "allows different users to have memberships in same site" do
      other_user = User.create!(first_name: 'Jane', email: 'jane@example.com', password: 'AAbbcc1122!!')

      membership1 = Membership.create!(site: site, user: user)
      membership2 = Membership.new(site: site, user: other_user)

      expect(membership1).to be_valid
      expect(membership2).to be_valid
    end
  end

  describe "creation" do
    it "can be created with valid site and user" do
      membership = Membership.new(site: site, user: user)
      expect(membership).to be_valid
    end
  end
end