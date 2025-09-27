require 'spec_helper'

RSpec.describe Authentication::HashHelper do
  # Test class that includes the HashHelper module
  class TestClass
    include Authentication::HashHelper

    # Make the private methods accessible for testing
    def public_site_salt
      site_salt
    end

    def public_hash_string(string, salt = site_salt)
      hash_string(string, salt)
    end
  end

  let(:test_instance) { TestClass.new }

  describe '#site_salt' do
    it 'returns AUTHENTICATION_SALT when defined' do
      expect(test_instance.public_site_salt).to eq('test-salt')
    end

    it 'falls back to Rails.root when AUTHENTICATION_SALT is not defined' do
      # Temporarily remove the AUTHENTICATION_SALT constant
      original_salt = AUTHENTICATION_SALT
      Object.send(:remove_const, :AUTHENTICATION_SALT)

      # Mock Rails.root
      rails_module = Module.new
      rails_module.define_singleton_method(:root) { '/test/rails/root' }
      stub_const('Rails', rails_module)

      expect(test_instance.public_site_salt).to eq('/test/rails/root')

      # Restore the constant
      Object.const_set(:AUTHENTICATION_SALT, original_salt)
    end
  end

  describe '#hash_string' do
    it 'generates a hash using the provided salt' do
      result = test_instance.public_hash_string('password', 'custom_salt')
      expected = Digest::SHA1.hexdigest('custom_salt---password')
      expect(result).to eq(expected)
    end

    it 'uses site_salt as default' do
      result = test_instance.public_hash_string('password')
      expected = Digest::SHA1.hexdigest('test-salt---password')
      expect(result).to eq(expected)
    end
  end
end