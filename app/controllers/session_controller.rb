class SessionController < BaseController
  renders_with_error_proc :below_field

  layout "login"

  def new
    @user = User.new
  end

  def create
    if authenticate_user(params[:user])
      redirect_to params[:return_to] || "/", notice: "Logged in successfully."
    else
      @user = User.new(email: params[:user][:email])
      @remember_me = params[:user][:remember_me]
      flash.now.alert = "Could not login with this email and password."
      render action: "new"
    end
  end

  # Tokens are minted by User#login_as_token, which scopes them to :login_as and
  # gives them an expiry. Without both, any token ever generated stays a valid
  # admin credential until secret_key_base is rotated.
  def token_login
    user_id = User.verify_login_as_token(params[:token])
    if user_id && (user = User.find_by(id: user_id))
      login_user!(user)
      redirect_to "/admin", notice: "You are now logged in as #{user.name}."
    else
      redirect_to "/login", alert: "Invalid or expired login token."
    end
  end

  def destroy
    logout
    redirect_to "/", notice: "Logged out successfully."
  end
end
