class UserSession < Authlogic::Session::Base
  httponly true
  secure true
  same_site "Lax"
  remember_me_for 2.weeks

  validate :must_be_verified

  private

    # Unverified accounts could never log in with a password under the previous
    # scheme; the reset/verification flows go through the perishable token
    # instead, which does not build a session.
    def must_be_verified
      return if attempted_record.nil? || attempted_record.verified?

      errors.add(:base, "Your account has not been verified yet.")
    end
end
