require 'authentication/hash_helper'
require 'active_support/security_utils'
require 'bcrypt'

module Authentication
  # Implements a basic salted hash authentication is the model's table.
  # The model must implement the fields "password_hash" and
  # "password_salt". If those fields are not implemented then this
  # module cannot authenticate the user.
  #
  # New passwords are hashed with bcrypt (key-stretched, self-contained
  # salt). Existing accounts created under the legacy single-round salted
  # SHA1 scheme still authenticate, and are transparently re-hashed with
  # bcrypt on their next successful login (rehash-on-login) so the whole
  # user base migrates over time.
  #
  # NOTE: bcrypt hashes are 60 characters, so the password_hash column must
  # be wide enough to hold them (the legacy schema limited it to 40).
  #
  # NOTE: There is a hidden feature here. If the model contains
  # the column "verified_at" then the user will not authenticate
  # until the verified_at column has a value. This is to support the
  # common practice of requiring a user to verify their email address
  # before being able to login. If the column is not defined then
  # the user can login as long as their password is correct.
  class SaltedHash
    include HashHelper

    # Carries out actual authentication procedure. If the password
    # given is correct for the given user then true is returned.
    # Otherwise false will be returned.
    def authenticate(user, password)
      return false unless valid_model?(user)
      return false if password.blank? || user.password_hash.blank?
      return false if user.respond_to?(:verified_at) && user.verified_at.nil?

      if bcrypt_hash?(user.password_hash)
        BCrypt::Password.new(user.password_hash) == password
      elsif legacy_hash_matches?(user, password)
        rehash_with_bcrypt!(user, password)
        true
      else
        false
      end
    end

    # Will assign a new password for the given user, hashed with bcrypt.
    def assign_password(user, password)
      return unless valid_model? user

      user.password_salt = hash_string "salt-#{Time.zone.now}"
      user.password_hash = BCrypt::Password.create(password).to_s
    end

    private

    # bcrypt hashes start with a $2a$/$2b$/$2y$ version tag; the legacy
    # scheme stored a bare 40-char hex SHA1 digest.
    def bcrypt_hash?(hash)
      hash.to_s.start_with?("$2a$", "$2b$", "$2y$")
    end

    def legacy_hash_matches?(user, password)
      expected = hash_string(password, user.password_salt)
      ActiveSupport::SecurityUtils.secure_compare(expected, user.password_hash.to_s)
    end

    # Transparently upgrade a legacy SHA1 account to bcrypt on login.
    def rehash_with_bcrypt!(user, password)
      assign_password(user, password)
      return unless user.persisted?
      user.update_columns(
        password_salt: user.password_salt,
        password_hash: user.password_hash,
      )
    end

    # True if password_hash and password_salt not in the table
    def valid_model?(user)
      user.class.includes_all_columns? :password_hash, :password_salt
    end
  end
end
