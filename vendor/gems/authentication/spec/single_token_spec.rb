require 'spec_helper'

RSpec.describe Authentication::SingleToken do
  include Authentication::HashHelper

  let(:tokener) { described_class.new }
  let(:user)    { User.create!(name: 'Joe') }

  it 'assigns token and expiration' do
    key = tokener.assign_token(user, 'standard', 3.days.from_now)
    user.save!
    user.reload
    expect(user.token_key).to eq(hash_string(key))
    expect(user.token_expiration.to_date).to eq(3.days.from_now.to_date)
  end

  it 'authenticates valid token and rejects invalid' do
    key = tokener.assign_token(user, 'standard', 3.days.from_now)
    user.save!
    user.reload
    expect(tokener.authenticate(user, key)).to be true
    expect(tokener.authenticate(user, 'invalid key')).to be false
  end

  it 'rejects expired token' do
    key = tokener.assign_token(user, 'past', 1.day.ago)
    user.save!
    user.reload
    expect(tokener.authenticate(user, key)).to be false
  end

  it 'authenticates token without expiration' do
    key = tokener.assign_token(user, 'no_exp', nil)
    user.save!
    user.reload
    expect(tokener.authenticate(user, key)).to be true
  end
end

