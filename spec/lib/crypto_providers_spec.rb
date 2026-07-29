require "rails_helper"

RSpec.describe "password hashing" do
  let(:password) { "AAbbcc1122!!" }

  # Reproduce the pre-bcrypt scheme independently of the code under test, so
  # these fixtures stand in for rows written before the migration.
  def legacy_sha1(plaintext, salt)
    Digest::SHA1.hexdigest("#{salt}---#{plaintext}")
  end

  describe Adva::CryptoProviders::BCrypt do
    it "hashes the password alone, ignoring the salt token authlogic passes" do
      hash = described_class.encrypt(password, "some-salt")

      expect(BCrypt::Password.new(hash) == password).to be true
    end

    it "matches hashes written before authlogic, which had no salt mixed in" do
      hash = BCrypt::Password.create(password).to_s

      expect(described_class.matches?(hash, password, "any-salt")).to be true
      expect(described_class.matches?(hash, "wrong", "any-salt")).to be false
    end

    it "does not match a legacy sha1 digest" do
      expect(described_class.matches?(legacy_sha1(password, "salt"), password, "salt")).to be false
    end
  end

  describe Adva::CryptoProviders::LegacySaltedSha1 do
    it "matches the legacy salted sha1 scheme" do
      salt = "legacy-salt"

      expect(described_class.matches?(legacy_sha1(password, salt), password, salt)).to be true
      expect(described_class.matches?(legacy_sha1(password, salt), "wrong", salt)).to be false
    end

    it "rejects a blank hash" do
      expect(described_class.matches?(nil, password, "salt")).to be false
      expect(described_class.matches?("", password, "salt")).to be false
    end

    it "refuses to hash new passwords" do
      expect { described_class.encrypt(password) }.to raise_error(NotImplementedError)
    end
  end

  describe User do
    it "stores new passwords as bcrypt" do
      user = User.create!(first_name: "New", email: "new-bcrypt@example.com",
        password: password, verified_at: Time.now)

      expect(user.password_hash).to start_with("$2")
      expect(user.valid_password?(password)).to be true
      expect(user.valid_password?("wrong")).to be false
    end

    context "an account still on the legacy sha1 scheme" do
      let(:legacy_salt) { Digest::SHA1.hexdigest("some-legacy-salt") }

      let!(:legacy_user) do
        user = User.create!(first_name: "Legacy", email: "legacy@example.com",
          password: password, verified_at: Time.now)
        user.update_columns(
          password_salt: legacy_salt,
          password_hash: legacy_sha1(password, legacy_salt),
        )
        user.reload
      end

      it "is stored as a 40-char hex sha1 digest" do
        expect(legacy_user.password_hash).to match(/\A[0-9a-f]{40}\z/)
      end

      it "authenticates with the correct legacy password" do
        expect(legacy_user.valid_password?(password)).to be true
      end

      it "rejects an incorrect legacy password" do
        expect(legacy_user.valid_password?("wrong")).to be false
      end

      it "transparently rehashes with bcrypt on a successful login" do
        legacy_user.valid_password?(password)

        expect(legacy_user.reload.password_hash).to start_with("$2")
        expect(legacy_user.valid_password?(password)).to be true
        expect(legacy_user.valid_password?("wrong")).to be false
      end

      it "does not rehash after a failed login" do
        legacy_user.valid_password?("wrong")

        expect(legacy_user.reload.password_hash).to match(/\A[0-9a-f]{40}\z/)
      end

      it "authenticates through User.authenticate" do
        expect(User.authenticate(email: legacy_user.email, password: password)).to eq(legacy_user)
        expect(User.authenticate(email: legacy_user.email, password: "wrong")).to be_falsey
      end
    end
  end
end
