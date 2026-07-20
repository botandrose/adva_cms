require 'spec_helper'

RSpec.describe Authentication::SaltedHash do
  let(:password) { 'foobazzle' }
  let(:crypter)  { described_class.new }
  let(:user)     { User.create!(name: 'Joe') }

  # Reproduce the legacy single-round salted SHA1 scheme independently of the
  # implementation under test, so these fixtures represent pre-migration rows.
  def legacy_sha1(plaintext, salt)
    Digest::SHA1.hexdigest("#{salt}---#{plaintext}")
  end

  describe 'assigning a password (bcrypt)' do
    before do
      crypter.assign_password(user, password)
      user.save!
      user.reload
    end

    it 'assigns password salt and hash' do
      expect(user.password_salt).not_to be_nil
      expect(user.password_hash).not_to be_nil
    end

    it 'stores a bcrypt hash, not a bare SHA1 digest' do
      expect(user.password_hash).to start_with('$2')
      expect(user.password_hash.length).to eq(60)
      expect(BCrypt::Password.new(user.password_hash) == password).to be true
    end

    it 'authenticates with correct password and rejects invalid' do
      expect(crypter.authenticate(user, password)).to be true
      expect(crypter.authenticate(user, 'false password')).to be false
    end

    it 'rejects a blank password' do
      expect(crypter.authenticate(user, '')).to be false
      expect(crypter.authenticate(user, nil)).to be false
    end

    it 'fails to authenticate when required columns are missing' do
      class << User; alias_method :backup_column_names, :column_names end
      begin
        def User.column_names; %w(id name password) end
        expect(crypter.authenticate(user, password)).to be false
      ensure
        class << User; alias_method :column_names, :backup_column_names end
      end
    end
  end

  describe 'legacy SHA1 accounts' do
    let(:legacy_salt) { Digest::SHA1.hexdigest('some-legacy-salt') }

    let(:legacy_user) do
      User.create!(
        name: 'Legacy',
        password_salt: legacy_salt,
        password_hash: legacy_sha1(password, legacy_salt),
      )
    end

    it 'is stored as a 40-char hex SHA1 digest' do
      expect(legacy_user.password_hash).to match(/\A[0-9a-f]{40}\z/)
    end

    it 'authenticates with the correct legacy password' do
      expect(crypter.authenticate(legacy_user, password)).to be true
    end

    it 'rejects an incorrect legacy password' do
      expect(crypter.authenticate(legacy_user, 'wrong')).to be false
    end

    it 'transparently re-hashes with bcrypt on successful login' do
      crypter.authenticate(legacy_user, password)
      legacy_user.reload

      expect(legacy_user.password_hash).to start_with('$2')
      expect(BCrypt::Password.new(legacy_user.password_hash) == password).to be true
    end

    it 'still authenticates via bcrypt after being re-hashed' do
      crypter.authenticate(legacy_user, password)
      legacy_user.reload

      expect(crypter.authenticate(legacy_user, password)).to be true
      expect(crypter.authenticate(legacy_user, 'wrong')).to be false
    end

    it 'does not re-hash after a failed login' do
      original_hash = legacy_user.password_hash
      crypter.authenticate(legacy_user, 'wrong')
      legacy_user.reload

      expect(legacy_user.password_hash).to eq(original_hash)
    end
  end
end
