class PasswordController < BaseController
  renders_with_error_proc :below_field
  layout 'login'

  def new
  end

  def create
    if user = User.find_by_email(params[:user][:email])
      token = user.assign_token 'password'
      user.save!
      trigger_event user, :password_reset_requested, :token => "#{user.id};#{token}"
      redirect_to edit_password_url, notice: "If the given email address exists in our system, we have just sent you an email with information on how to reset your password."
    else
      render :action => :new
    end
  end

  def edit
  end

  def update
    if current_user && current_user.update(params[:user].slice(:password))
      trigger_event current_user, :password_updated
      authenticate_user(:email => current_user.email, :password => params[:user][:password])
      redirect_to "/", notice: "Your password was changed successfully."
    else
      params[:token] = nil # ugh
      flash.now.alert = "Your password could not be changed."
      render :action => :edit
    end
  end
end
