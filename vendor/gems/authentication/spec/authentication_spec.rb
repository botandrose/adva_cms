require 'spec_helper'

RSpec.describe 'Authentication dispatch' do
  # Recorder that logs calls and returns configured responses
  class AuthRecorder
    def initialize(*args)
      @record = []
      @returns = {}
    end
    def method_missing(meth, *args)
      @record << [meth, *args]
      @returns[meth]
    end
    def send_back(meth, ret)
      @returns[meth] = ret
    end
    def last_message
      @record.last
    end
    def cleanup
      @record = []
      @returns = {}
    end
    def assign_token(*args) = method_missing(:assign_token, *args)
    def assign_password(*args) = method_missing(:assign_password, *args)
  end

  class RecordedUser < User
    acts_as_authenticated_user \
      authenticate_with: ['AuthRecorder'] * 2,
      token_with: ['AuthRecorder'] * 2
  end

  after do
    (RecordedUser.authentication_modules + RecordedUser.token_modules).each(&:cleanup)
  end

  def jack_with_test_password
    @jack = RecordedUser.new(first_name: 'Jack')
    @jack.password = 'test'
    @jack.save!
    @jack.reload
  end

  def jack_token
    @jack = RecordedUser.new(first_name: 'Jack')
    tok = @jack.assign_token('test')
    @jack.save!
    @jack.reload
    tok
  end

  def jack_test_auth_message(*auths)
    auths.each do |auth|
      message = auth.last_message
      expect(message[0]).to eq(:authenticate)
      expect(message[1]).to eq(@jack)
      expect(message[2]).to eq('test')
    end
  end

  def jack_test_token_message(token, *toks)
    toks.each do |tok|
      message = tok.last_message
      expect(message[0]).to eq(:authenticate)
      expect(message[1]).to eq(@jack)
      expect(message[2]).to eq(token)
    end
  end

  def jack_test_assign_tok_message(*toks)
    toks.each do |tok|
      message = tok.last_message
      expect(message[0]).to eq(:assign_token)
      expect(message[1]).to eq(@jack)
      expect(message[3].to_date).to eq(3.days.from_now.to_date)
    end
  end

  it 'creates a user without token or password' do
    expect { User.create!(first_name: 'John', last_name: 'Doe') }.not_to raise_error
  end

  it 'authenticates via first module success' do
    first = RecordedUser.authentication_modules.first
    first.send_back(:authenticate, true)
    jack_with_test_password
    expect(@jack.authenticate('test')).to be true
    jack_test_auth_message(first)
  end

  it 'authenticates via later module if first fails' do
    first = RecordedUser.authentication_modules.first
    first.send_back(:authenticate, false)
    last = RecordedUser.authentication_modules.last
    last.send_back(:authenticate, true)
    jack_with_test_password
    expect(@jack.authenticate('test')).to be true
    jack_test_auth_message(first, last)
  end

  it 'fails authentication when all modules fail' do
    first = RecordedUser.authentication_modules.first
    first.send_back(:authenticate, false)
    last = RecordedUser.authentication_modules.last
    last.send_back(:authenticate, false)
    jack_with_test_password
    expect(@jack.authenticate('test')).to be false
    jack_test_auth_message(first, last)
  end

  it 'authenticates with token via first module' do
    first = RecordedUser.token_modules.first
    first.send_back(:authenticate, true)
    tok = jack_token
    expect(@jack.authenticate(tok)).to be true
    jack_test_token_message(tok, first)
  end

  it 'authenticates with token via later module' do
    first = RecordedUser.token_modules.first
    first.send_back(:authenticate, false)
    last = RecordedUser.token_modules.last
    last.send_back(:authenticate, true)
    tok = jack_token
    expect(@jack.authenticate(tok)).to be true
    jack_test_token_message(tok, first, last)
  end

  it 'fails token authentication when all modules fail' do
    first = RecordedUser.token_modules.first
    first.send_back(:authenticate, false)
    last = RecordedUser.token_modules.last
    last.send_back(:authenticate, false)
    tok = jack_token
    expect(tok).to be_nil
    expect(@jack.authenticate(tok)).to be false
    jack_test_token_message(tok, first, last)
  end

  it 'assigns token using first successful module' do
    first = RecordedUser.token_modules.first
    first.send_back(:assign_token, 'test_token')
    tok = jack_token
    expect(tok).to eq('test_token')
    jack_test_assign_tok_message(first)
  end

  it 'assigns token using later module if first fails' do
    first = RecordedUser.token_modules.first
    first.send_back(:assign_token, nil)
    last = RecordedUser.token_modules.last
    last.send_back(:assign_token, 'last_token')
    tok = jack_token
    expect(tok).to eq('last_token')
    jack_test_assign_tok_message(first, last)
  end

  it 'returns nil token when all modules fail to assign' do
    first = RecordedUser.token_modules.first
    first.send_back(:assign_token, nil)
    last = RecordedUser.token_modules.last
    last.send_back(:assign_token, nil)
    tok = jack_token
    expect(tok).to be_nil
    jack_test_assign_tok_message(first, last)
  end

  it 'assigns password via all auth modules' do
    first = RecordedUser.authentication_modules.first
    last = RecordedUser.authentication_modules.last
    jane = RecordedUser.new(first_name: 'Jane', last_name: 'Doe')
    jane.password = 'testing'
    jane.save!
    jane.reload
    [first, last].each do |auth|
      message = auth.last_message
      expect(message[0]).to eq(:assign_password)
      expect(message[1]).to eq(jane)
      expect(message[2]).to eq('testing')
    end
  end

  it 'does not overwrite password on blank' do
    jenny = User.new(first_name: 'Jenny')
    jenny.password = 'test'
    jenny.save!
    jenny.reload
    jenny.password = ''
    jenny.save!
    expect(jenny.authenticate('test')).to be true
  end

  it 'assigns and saves token in one step with assign_token!' do
    user = User.new(first_name: 'Test', last_name: 'User')
    user.save!

    # Mock the single token module to return a token
    allow_any_instance_of(Authentication::SingleToken).to receive(:assign_token).and_return('test_token_123')

    token = user.assign_token!('password', 3.days.from_now)

    expect(token).to eq('test_token_123')
    expect(user.changed?).to be false # Should be saved
  end

  describe 'real password authentication' do
    it 'authenticates with SaltedHash password authentication' do
      user = User.new(first_name: 'Test', name: 'Test User')
      user.password = 'test_password_123'
      user.save!
      user.reload

      expect(user.authenticate('test_password_123')).to be true
      expect(user.authenticate('wrong_password')).to be false
    end

    it 'supports class-level authenticate method pattern' do
      user = User.create!(first_name: 'Test', name: 'Test User', password: 'test_password_123')

      # Define a class method similar to what adva User model has
      def User.authenticate(credentials)
        return false unless user = User.find_by(name: credentials[:name])
        user.authenticate(credentials[:password]) ? user : false
      end

      result = User.authenticate(name: 'Test User', password: 'test_password_123')
      expect(result).to eq(user)

      result = User.authenticate(name: 'Test User', password: 'wrong_password')
      expect(result).to be false

      result = User.authenticate(name: 'Wrong User', password: 'test_password_123')
      expect(result).to be false
    end
  end

end
