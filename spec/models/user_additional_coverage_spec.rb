require "rails_helper"

RSpec.describe User, type: :model do
  let(:site1) { Site.create!(name: 'Site 1', title: 'Site 1', host: 'site1.example.com') }
  let(:site2) { Site.create!(name: 'Site 2', title: 'Site 2', host: 'site2.example.com') }

  describe ".authenticate" do
    let!(:user) { User.create!(first_name: 'John', email: 'john@example.com', password: 'AAbbcc1122!!', verified_at: Time.now) }

    it "returns user when credentials are valid" do
      result = User.authenticate(email: 'john@example.com', password: 'AAbbcc1122!!')
      expect(result).to eq(user)
    end

    it "returns false when email not found" do
      result = User.authenticate(email: 'nonexistent@example.com', password: 'AAbbcc1122!!')
      expect(result).to be_falsy
    end

    it "returns false when password is wrong" do
      result = User.authenticate(email: 'john@example.com', password: 'wrongpassword')
      expect(result).to be_falsy
    end
  end

  describe ".anonymous" do
    it "creates anonymous user with given attributes" do
      user = User.anonymous(first_name: 'Guest', email: 'guest@example.com')
      expect(user.anonymous?).to be_truthy
      expect(user.first_name).to eq('Guest')
      expect(user.email).to eq('guest@example.com')
    end
  end

  describe "#update_memberships" do
    let(:user) { User.create!(first_name: 'John', email: 'john@example.com', password: 'AAbbcc1122!!', verified_at: Time.now) }

    it "adds membership when active is true" do
      user.update_memberships(site1.id.to_s => true)
      expect(user.member_of?(site1)).to be_truthy
    end

    it "removes membership when active is false" do
      user.sites << site1
      user.update_memberships(site1.id.to_s => false)
      expect(user.member_of?(site1)).to be_falsy
    end

    it "does not add duplicate memberships" do
      user.sites << site1
      expect {
        user.update_memberships(site1.id.to_s => true)
      }.not_to change { user.sites.count }
    end

    it "handles multiple memberships" do
      user.update_memberships(
        site1.id.to_s => true,
        site2.id.to_s => true
      )
      expect(user.member_of?(site1)).to be_truthy
      expect(user.member_of?(site2)).to be_truthy
    end
  end

  describe "#member_of?" do
    let(:user) { User.create!(first_name: 'John', email: 'john@example.com', password: 'AAbbcc1122!!', verified_at: Time.now) }

    it "returns true when user is member of site" do
      user.sites << site1
      expect(user.member_of?(site1)).to be_truthy
    end

    it "returns false when user is not member of site" do
      expect(user.member_of?(site1)).to be_falsy
    end
  end

  describe "#verify!" do
    let(:user) { User.create!(first_name: 'John', email: 'john@example.com', password: 'AAbbcc1122!!') }

    it "sets verified_at when not previously verified" do
      expect(user.verified_at).to be_nil
      user.verify!
      expect(user.verified_at).not_to be_nil
    end

    it "does not change verified_at when already verified" do
      user.update!(verified_at: 1.day.ago)
      original_time = user.verified_at
      user.verify!
      expect(user.verified_at).to eq(original_time)
    end
  end

  describe "#verified?" do
    it "returns true when verified_at is set" do
      user = User.new(verified_at: Time.now)
      expect(user.verified?).to be_truthy
    end

    it "returns false when verified_at is nil" do
      user = User.new(verified_at: nil)
      expect(user.verified?).to be_falsy
    end
  end

  describe "#registered?" do
    it "returns true for non-anonymous persisted user" do
      user = User.create!(first_name: 'John', email: 'john@example.com', password: 'AAbbcc1122!!', verified_at: Time.now)
      expect(user.registered?).to be_truthy
    end

    it "returns false for new record" do
      user = User.new(first_name: 'John', email: 'john@example.com')
      expect(user.registered?).to be_falsy
    end

    it "returns false for anonymous user" do
      user = User.anonymous(first_name: 'Guest', email: 'guest@example.com')
      user.save!
      expect(user.registered?).to be_falsy
    end
  end

  describe "#name=" do
    it "sets first_name" do
      user = User.new
      user.name = 'John Doe'
      expect(user.first_name).to eq('John Doe')
    end
  end

  describe "#name" do
    it "returns first_name when no last_name" do
      user = User.new(first_name: 'John')
      expect(user.name).to eq('John')
    end

    it "returns full name when both first_name and last_name present" do
      user = User.new(first_name: 'John', last_name: 'Doe')
      expect(user.name).to eq('John Doe')
    end
  end

  describe "#to_s" do
    it "returns the name" do
      user = User.new(first_name: 'John', last_name: 'Doe')
      expect(user.to_s).to eq('John Doe')
    end
  end

  describe "#email_with_name" do
    it "formats email with name" do
      user = User.new(first_name: 'John', last_name: 'Doe', email: 'john@example.com')
      expect(user.email_with_name).to eq('John Doe <john@example.com>')
    end
  end

  describe "#homepage" do
    it "returns nil when homepage is nil" do
      user = User.new
      expect(user.homepage).to be_nil
    end

    it "adds http:// prefix when missing" do
      user = User.new
      user[:homepage] = 'example.com'
      expect(user.homepage).to eq('http://example.com')
    end

    it "does not add prefix when already present" do
      user = User.new
      user[:homepage] = 'http://example.com'
      expect(user.homepage).to eq('http://example.com')
    end
  end

  describe "#first_name_from_email" do
    it "returns first_name when not blank" do
      user = User.new(first_name: 'John', email: 'john.doe@example.com')
      expect(user.first_name_from_email).to eq('John')
    end

    it "returns email prefix when first_name is blank and email exists" do
      user = User.new(first_name: '', email: 'john.doe@example.com')
      expect(user.first_name_from_email).to eq('john.doe')
    end

    it "returns first_name when both first_name and email are blank" do
      user = User.new(first_name: '', email: nil)
      expect(user.first_name_from_email).to eq('')
    end
  end

  describe "#attributes=" do
    let(:user) { User.new }

    it "handles memberships in attributes" do
      allow(user).to receive(:update_memberships)

      user.attributes = {
        first_name: 'John',
        email: 'john@example.com',
        memberships: { site1.id.to_s => true }
      }

      expect(user).to have_received(:update_memberships).with({ site1.id.to_s => true })
      expect(user.first_name).to eq('John')
    end
  end

  describe "password complexity validation" do
    let(:user) { User.new(first_name: 'John', email: 'john@example.com') }

    it "accepts password with lowercase, uppercase, and numbers" do
      user.password = 'AAbbcc1122xx'
      user.valid?
      expect(user.errors[:password]).to be_empty
    end

    it "accepts password with lowercase, uppercase, and symbols" do
      user.password = 'AAbbcc!!!!xx'
      user.valid?
      expect(user.errors[:password]).to be_empty
    end

    it "accepts password with numbers, uppercase, and symbols" do
      user.password = 'AA1122!!!!xx'
      user.valid?
      expect(user.errors[:password]).to be_empty
    end

    it "rejects password with only lowercase and uppercase" do
      user.password = 'AAbbccddeexx'
      user.valid?
      expect(user.errors[:password]).to include('must contain at least 3 of the following: lowercase letters, uppercase letters, numbers, or special characters')
    end

    it "rejects password with only one character type" do
      user.password = 'aaaaaaaaaaaa'
      user.valid?
      expect(user.errors[:password]).to include('must contain at least 3 of the following: lowercase letters, uppercase letters, numbers, or special characters')
    end
  end

  describe "password_required?" do
    it "returns false for anonymous users" do
      user = User.anonymous
      expect(user.send(:password_required?)).to be_falsy
    end

    it "returns true when password_hash is nil for non-anonymous user" do
      user = User.new(first_name: 'John', email: 'john@example.com')
      expect(user.send(:password_required?)).to be_truthy
    end

    it "returns true when password is present for non-anonymous user" do
      user = User.new(first_name: 'John', email: 'john@example.com', password: 'test')
      user.password_hash = 'existing_hash'
      expect(user.send(:password_required?)).to be_truthy
    end
  end
end