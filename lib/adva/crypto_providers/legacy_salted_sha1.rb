require "digest/sha1"
require "active_support/security_utils"

module Adva
  module CryptoProviders
    # The single-round salted SHA1 scheme adva used before bcrypt.
    #
    # Registered via transition_from_crypto_providers so accounts that have not
    # logged in since the bcrypt migration still authenticate, and get rehashed
    # with bcrypt on that login. Verification only -- encrypt is never called on
    # a transition provider, and must not be.
    class LegacySaltedSha1
      class << self
        def matches?(hash, *tokens)
          hash = hash.to_s
          return false if hash.blank?

          password, salt = tokens.flatten
          ActiveSupport::SecurityUtils.secure_compare(
            ::Digest::SHA1.hexdigest("#{salt}---#{password}"),
            hash,
          )
        end

        def encrypt(*)
          raise NotImplementedError, "legacy SHA1 hashes are verify-only; new passwords use bcrypt"
        end
      end
    end
  end
end
