class PasswordController < BaseController
  renders_with_error_proc :below_field
  layout "login"

  skip_forgery_protection only: :update

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
end
