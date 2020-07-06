class PasswordController < BaseController
  renders_with_error_proc :below_field
  layout 'login'

  def new
  end

  def create
    flash[:notice] = t(:'adva.passwords.flash.create.notification')
    if user = User.find_by_email(params[:user][:email])
      token = user.assign_token 'password'
      user.save!
      trigger_event user, :password_reset_requested, :token => "#{user.id};#{token}"
      redirect_to edit_password_url
    else
      render :action => :new
    end
  end

  def edit
  end

  def update
    if current_user && current_user.update(params[:user].slice(:password))
      trigger_event current_user, :password_updated
      flash[:notice] = t(:'adva.passwords.flash.update.success')
      authenticate_user(:email => current_user.email, :password => params[:user][:password])
      redirect_to "/"
    else
      params[:token] = nil # ugh
      flash[:error] = t(:'adva.passwords.flash.update.failure')
      render :action => :edit
    end
  end
end
