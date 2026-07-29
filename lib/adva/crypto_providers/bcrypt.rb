require "bcrypt"

module Adva
  module CryptoProviders
    # bcrypt, hashing the password alone.
    #
    # Authlogic passes [password, salt] whenever password_salt_field is set, and
    # its own bcrypt provider concatenates them. Adva's hashes predate authlogic
    # and are plain BCrypt::Password.create(password), so the salt token is
    # dropped here to keep every existing hash valid. bcrypt carries its own
    # per-hash salt regardless.
    #
    # No cost_matches? is defined, so authlogic never re-saves a password merely
    # because the configured cost drifted.
    class BCrypt
      class << self
        def encrypt(*tokens)
          ::BCrypt::Password.create(password_from(tokens))
        end

        def matches?(hash, *tokens)
          hash = new_from_hash(hash)
          return false if hash.blank?

          hash == password_from(tokens)
        end

        private

        def password_from(tokens)
          tokens.flatten.first.to_s
        end

        def new_from_hash(hash)
          ::BCrypt::Password.new(hash)
        rescue ::BCrypt::Errors::InvalidHash
          nil
        end
      end
    end
  end
end
