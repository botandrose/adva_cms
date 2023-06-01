class Admin::UsersController < Admin::BaseController
  before_action :set_user,  :only => [:show, :edit, :update, :destroy]
  before_action :authorize_access

  def index
    @users = User.where(admin: true).to_a + @site.users.to_a
  end

  def show
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(params[:user])
    @user.memberships.build(:site => @site) if @site and !@user.admin?

    if @user.save
      @user.verify! # TODO hu??
      trigger_events(@user)
      redirect_to [:admin, @user], notice: "The user has been created."
    else
      flash.now.alert = "The user could not be created."
      render :action => :new
    end
  end

  def edit
  end

  def update
    if @user.update(params[:user])
      trigger_events(@user)
      redirect_to [:admin, @user], notice: "The user has been updated."
    else
      flash.now.alert = "The user could not be updated."
      render :action => :edit
    end
  end

  def destroy
    if @user.destroy
      trigger_events(@user)
      redirect_to [:admin, :users], notice: "The user has been deleted."
    else
      flash.now.alert = "The user could not be deleted."
      render :action => :edit
    end
  end

  private

    def set_menu
      @menu = Menus::Admin::Users.new
    end

    def set_user
      @user = User.find(params[:id])
    end

    # FIXME extract this and use Rbac contexts instead
    def authorize_access
      redirect_to admin_sites_url unless @site || current_user.admin?
    end
end
