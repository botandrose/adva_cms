class SessionController < BaseController
  renders_with_error_proc :below_field

  skip_before_action :verify_authenticity_token # disable forgery protection

  layout 'login'

  def new
    @user = User.new
  end

  def create
    if authenticate_user(params[:user])
      remember_me! if params[:user][:remember_me]
      redirect_to params[:return_to] || '/', notice: "Logged in successfully."
    else
      @user = User.new(:email => params[:user][:email])
      @remember_me = params[:user][:remember_me]
      flash.now.alert = "Could not login with this email and password."
      render :action => 'new'
    end
  end

  def destroy
    logout
    redirect_to '/', notice: "Logged out successfully."
  end
end
