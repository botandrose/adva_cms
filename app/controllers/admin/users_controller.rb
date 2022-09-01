class Admin::UsersController < Admin::BaseController
  before_action :set_users, :only => [:index]
  before_action :set_user,  :only => [:show, :edit, :update, :destroy]
  before_action :authorize_access

  def index
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
      flash[:notice] = t(:'adva.users.flash.create.success')
      redirect_to admin_user_url(@user)
    else
      flash.now[:error] = t(:'adva.users.flash.create.failure')
      render :action => :new
    end
  end

  def edit
  end

  def update
    if @user.update(params[:user])
      trigger_events(@user)
      flash[:notice] = t(:'adva.users.flash.update.success')
      redirect_to admin_user_url(@user)
    else
      flash.now[:error] = t(:'adva.users.flash.update.failure')
      render :action => :edit
    end
  end

  def destroy
    if @user.destroy
      trigger_events(@user)
      flash[:notice] = t(:'adva.users.flash.destroy.success')
      redirect_to admin_users_url
    else
      flash.now[:error] = t(:'adva.users.flash.destroy.failure')
      render :action => :edit
    end
  end

  private

    def set_menu
      @menu = Menus::Admin::Users.new
    end

    def set_users
      @users = @site.users
    end

    def set_user
      @user = User.find(params[:id])
    end

    # FIXME extract this and use Rbac contexts instead
    def authorize_access
      redirect_to admin_sites_url unless @site || current_user.admin?
    end
end
