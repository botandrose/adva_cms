require 'spec_helper'

RSpec.describe 'acts_as_authenticated_user options' do
  class UserNoArgs < ActiveRecord::Base
    acts_as_authenticated_user
  end

  class BasicAuthMod; end
  class BasicTokenMod; end

  class UserWithAuthMod < ActiveRecord::Base
    acts_as_authenticated_user authenticate_with: 'BasicAuthMod'
  end

  class UserWithTokenMod < ActiveRecord::Base
    acts_as_authenticated_user token_with: 'BasicTokenMod'
  end

  class ArgAuthMod
    attr_accessor :args
    def initialize(*args)
      self.args = args
    end
  end
  class AnotherArgAuthMod < ArgAuthMod; end

  class UserWithMultipleMods < ActiveRecord::Base
    acts_as_authenticated_user authenticate_with: ['BasicAuthMod', 'Authentication::SaltedHash']
  end

  class UserWithArgMod < ActiveRecord::Base
    acts_as_authenticated_user authenticate_with: { 'ArgAuthMod' => { server: 'test' } }
  end

  class UserWithMultipleArgs < ActiveRecord::Base
    acts_as_authenticated_user authenticate_with: [
      { 'ArgAuthMod' => { server: 'test' } },
      { 'AnotherArgAuthMod' => { server: 'testing' } }
    ]
  end

  it 'uses default modules when no args given' do
    auth_mods = UserNoArgs.authentication_modules
    token_mods = UserNoArgs.token_modules

    expect(auth_mods.size).to eq(1)
    expect(token_mods.size).to eq(2)

    expect(auth_mods.first).to be_a(Authentication::SaltedHash)
    expect(token_mods.first).to be_a(Authentication::RememberMe)
    expect(token_mods.last).to be_a(Authentication::SingleToken)
  end

  it 'accepts a single auth module' do
    auth_mods = UserWithAuthMod.authentication_modules
    expect(auth_mods.size).to eq(1)
    expect(auth_mods.first).to be_a(BasicAuthMod)
  end

  it 'accepts a single token module' do
    token_mods = UserWithTokenMod.token_modules
    expect(token_mods.size).to eq(1)
    expect(token_mods.first).to be_a(BasicTokenMod)
  end

  it 'accepts multiple modules' do
    auth_mods = UserWithMultipleMods.authentication_modules
    expect(auth_mods.size).to eq(2)
    expect(auth_mods.first).to be_a(BasicAuthMod)
    expect(auth_mods.last).to be_a(Authentication::SaltedHash)
  end

  it 'accepts a module with args' do
    auth_mods = UserWithArgMod.authentication_modules
    expect(auth_mods.size).to eq(1)
    expect(auth_mods.first).to be_a(ArgAuthMod)
    expect(auth_mods.first.args.first[:server]).to eq('test')
  end

  it 'accepts multiple modules with args' do
    auth_mods = UserWithMultipleArgs.authentication_modules
    expect(auth_mods.size).to eq(2)
    expect(auth_mods.first).to be_a(ArgAuthMod)
    expect(auth_mods.last).to be_a(AnotherArgAuthMod)
    expect(auth_mods.first.args.first[:server]).to eq('test')
    expect(auth_mods.last.args.first[:server]).to eq('testing')
  end
end

