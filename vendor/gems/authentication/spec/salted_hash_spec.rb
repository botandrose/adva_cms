require 'spec_helper'

RSpec.describe Authentication::SaltedHash do
  let(:password) { 'foobazzle' }
  let(:crypter)  { described_class.new }
  let(:user)     { User.create!(name: 'Joe') }

  before do
    crypter.assign_password(user, password)
    user.save!
    user.reload
  end

  it 'assigns password salt and hash' do
    expect(user.password_salt).not_to be_nil
    expect(user.password_hash).not_to be_nil
  end

  it 'authenticates with correct password and rejects invalid' do
    expect(crypter.authenticate(user, password)).to be true
    expect(crypter.authenticate(user, 'false password')).to be false
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

