require 'spec_helper'

RSpec.describe Authentication::RememberMe do
  include Authentication::HashHelper

  let(:tokener) { described_class.new }
  let(:user)    { User.create!(name: 'Joe') }

  it 'assigns remember me token' do
    key = tokener.assign_token(user, 'remember me')
    user.save!
    user.reload
    expect(user.remember_me).to eq(hash_string(key))
  end

  it 'authenticates with the token and not with invalid' do
    key = tokener.assign_token(user, 'remember me')
    user.save!
    user.reload
    expect(tokener.authenticate(user, key)).to be true
    expect(tokener.authenticate(user, 'invalid key')).to be false
  end

  it 'ignores expiration for remember me' do
    expired_key = tokener.assign_token(user, 'remember me', 1.day.ago)
    user.save!
    user.reload
    expect(tokener.authenticate(user, expired_key)).to be true
  end

  it 'does not assign for non-remember-me names' do
    expect(tokener.assign_token(user, 'invalid', 3.days.from_now)).to be_nil
  end
end

