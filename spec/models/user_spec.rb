require "rails_helper"

RSpec.describe User, type: :model do
  let(:site) { Site.create!(name: 'test', host: 'test.example.com') }

  it "validates presence of first_name and email" do
    u = User.new
    expect(u).not_to be_valid
    u.first_name = 'a'
    u.email = 'a@example.com'
    u.password = 'AAbbcc1122!!'
    expect(u).to be_valid
  end

  it "enforces password complexity when required" do
    u = User.new(first_name: 'a', email: 'a2@example.com', password: 'simple')
    expect(u).not_to be_valid
  end

  it "formats email_with_name and builds homepage with scheme" do
    u = User.new(first_name: 'Jane', last_name: 'Doe', email: 'jane@example.com', password: 'AAbbcc1122!!')
    expect(u.email_with_name).to eq('Jane Doe <jane@example.com>')

    u.homepage = 'example.com'
    expect(u.homepage).to eq('http://example.com')
    u.homepage = 'http://example.com'
    expect(u.homepage).to eq('http://example.com')
  end

  it "derives name and first_name_from_email when first_name blank" do
    u = User.new(email: 'nickname@example.com', password: 'AAbbcc1122!!')
    expect(u.first_name_from_email).to eq('nickname')
    u.first_name = 'Given'
    expect(u.first_name_from_email).to eq('Given')
    u.last_name = 'Surname'
    expect(u.name).to eq('Given Surname')
    u.last_name = nil
    expect(u.name).to eq('Given')
  end

  describe "associations" do
    it "has many memberships with dependent delete_all" do
      association = User.reflect_on_association(:memberships)
      expect(association.options[:dependent]).to eq(:delete_all)
    end

    it "has many sites through memberships" do
      association = User.reflect_on_association(:sites)
      expect(association.options[:through]).to eq(:memberships)
    end
  end

  describe "scopes" do
    let!(:verified_user) { User.create!(first_name: 'John', email: 'john@example.com', password: 'AAbbcc1122!!', verified_at: Time.current) }
    let!(:unverified_user) { User.create!(first_name: 'Jane', email: 'jane@example.com', password: 'AAbbcc1122!!') }
    let!(:admin_user) { User.create!(first_name: 'Admin', email: 'admin@example.com', password: 'AAbbcc1122!!', admin: true) }

    describe ".verified" do
      it "returns only verified users" do
        expect(User.verified).to include(verified_user)
        expect(User.verified).not_to include(unverified_user)
      end
    end

    describe ".admin" do
      it "returns only admin users" do
        expect(User.admin).to include(admin_user)
        expect(User.admin).not_to include(verified_user)
      end
    end
  end

  describe ".authenticate" do
    let!(:user) { User.create!(first_name: 'Test', email: 'test@example.com', password: 'AAbbcc1122!!', verified_at: Time.current) }

    it "returns user for valid credentials" do
      result = User.authenticate(email: 'test@example.com', password: 'AAbbcc1122!!')
      expect(result).to eq(user)
    end

    it "returns false for invalid email" do
      result = User.authenticate(email: 'wrong@example.com', password: 'AAbbcc1122!!')
      expect(result).to be_falsey
    end

    it "returns false for invalid password" do
      result = User.authenticate(email: 'test@example.com', password: 'wrongpassword')
      expect(result).to be_falsey
    end
  end

  describe ".anonymous" do
    it "creates an anonymous user" do
      user = User.anonymous(first_name: 'Anon')
      expect(user.anonymous?).to be_truthy
      expect(user.first_name).to eq('Anon')
    end
  end

  describe "#update_memberships" do
    let(:user) { User.create!(first_name: 'Test', email: 'test@example.com', password: 'AAbbcc1122!!') }
    let(:site1) { Site.create!(name: 'site1', host: 'site1.example.com') }
    let(:site2) { Site.create!(name: 'site2', host: 'site2.example.com') }

    it "adds membership when active is true" do
      user.update_memberships(site1.id.to_s => true)
      expect(user.member_of?(site1)).to be_truthy
    end

    it "removes membership when active is false" do
      user.sites << site1
      user.update_memberships(site1.id.to_s => false)
      expect(user.member_of?(site1)).to be_falsey
    end

    it "does not duplicate memberships" do
      user.sites << site1
      expect {
        user.update_memberships(site1.id.to_s => true)
      }.not_to change { user.sites.count }
    end
  end

  describe "#member_of?" do
    let(:user) { User.create!(first_name: 'Test', email: 'test@example.com', password: 'AAbbcc1122!!') }

    it "returns true when user is member of site" do
      user.sites << site
      expect(user.member_of?(site)).to be_truthy
    end

    it "returns false when user is not member of site" do
      expect(user.member_of?(site)).to be_falsey
    end
  end

  describe "#verified?" do
    let(:user) { User.create!(first_name: 'Test', email: 'test@example.com', password: 'AAbbcc1122!!') }

    it "returns true when verified_at is set" do
      user.update!(verified_at: Time.current)
      expect(user.verified?).to be_truthy
    end

    it "returns false when verified_at is nil" do
      expect(user.verified?).to be_falsey
    end
  end

  describe "#verify!" do
    let(:user) { User.create!(first_name: 'Test', email: 'test@example.com', password: 'AAbbcc1122!!') }

    it "sets verified_at when not already verified" do
      user.verify!
      expect(user.verified_at).not_to be_nil
    end

    it "does not change verified_at when already verified" do
      original_time = 1.day.ago
      user.update!(verified_at: original_time)
      user.verify!
      expect(user.verified_at.to_i).to eq(original_time.to_i)
    end
  end

  describe "#registered?" do
    it "returns true for persisted non-anonymous user" do
      user = User.create!(first_name: 'Test', email: 'test@example.com', password: 'AAbbcc1122!!')
      expect(user.registered?).to be_truthy
    end

    it "returns false for new record" do
      user = User.new(first_name: 'Test', email: 'test@example.com', password: 'AAbbcc1122!!')
      expect(user.registered?).to be_falsey
    end

    it "returns false for anonymous user" do
      user = User.anonymous(first_name: 'Anon')
      expect(user.registered?).to be_falsey
    end
  end

  describe "#name=" do
    let(:user) { User.new }

    it "sets first_name" do
      user.name = 'John Doe'
      expect(user.first_name).to eq('John Doe')
    end
  end

  describe "#to_s" do
    let(:user) { User.new(first_name: 'John', last_name: 'Doe') }

    it "returns the name" do
      expect(user.to_s).to eq('John Doe')
    end
  end

  describe "#homepage" do
    let(:user) { User.new }

    it "returns nil when homepage is not set" do
      expect(user.homepage).to be_nil
    end

    it "adds http:// prefix when missing" do
      user[:homepage] = 'example.com'
      expect(user.homepage).to eq('http://example.com')
    end

    it "does not modify URLs that already have http://" do
      user[:homepage] = 'http://example.com'
      expect(user.homepage).to eq('http://example.com')
    end
  end

  describe "password complexity validation" do
    let(:user) { User.new(first_name: 'Test', email: 'test@example.com') }

    it "requires at least 3 character types" do
      user.password = 'onlylowercase'
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include('must contain at least 3 of the following: lowercase letters, uppercase letters, numbers, or special characters')
    end

    it "passes with 3 character types" do
      user.password = 'Lower123!!!!' # lowercase, numbers, symbols
      expect(user).to be_valid
    end

    it "passes with 4 character types" do
      user.password = 'Lower123Upper!' # all 4 types
      expect(user).to be_valid
    end
  end

  describe "#attributes=" do
    let(:user) { User.new }

    it "processes memberships separately" do
      expect(user).to receive(:update_memberships).with({ site.id.to_s => true })
      user.attributes = {
        first_name: 'Test',
        email: 'test@example.com',
        memberships: { site.id.to_s => true }
      }
    end
  end
end
