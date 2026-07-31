class PasswordController < BaseController
  renders_with_error_proc :below_field
  layout "login"

  perishable_token_login!

  # The reset link's token is the credential, and the session cookie is often
  # gone by the time the form is submitted, so a valid token stands in for the
  # authenticity token. Session-authenticated changes still require one.
  skip_forgery_protection only: :update
  before_action :verify_authenticity_token, only: :update, unless: :password_reset_token?

  def new
  end

  def create
    if user = User.find_by_email(params[:user][:email])
      user.reset_perishable_token!
      trigger_event user, :password_reset_requested, token: user.perishable_token
      redirect_to edit_password_url, notice: "If the given email address exists in our system, we have just sent you an email with information on how to reset your password."
    else
      render action: :new
    end
  end

  def edit
  end

  def update
    password = params.dig(:user, :password)
    # Authlogic maintains the session itself when the password changes.
    if authenticated? && current_user.update(password: password)
      trigger_event current_user, :password_updated
      redirect_to "/", notice: "Your password was changed successfully."
    else
      params[:token] = nil # ugh
      flash.now.alert = "Your password could not be changed."
      render action: :edit
    end
  end

  private

    # Presence alone is not enough: an unrecognised token must not exempt a
    # request that is riding someone else's session.
    def password_reset_token?
      params[:token].present? && User.find_using_perishable_token(params[:token]).present?
    end
end
