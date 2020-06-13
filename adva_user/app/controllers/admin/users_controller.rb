class Admin::UsersController < Admin::BaseController
  before_action :set_users, :only => [:index]
  before_action :set_user,  :only => [:show, :edit, :update, :destroy]
  before_action :authorize_access
  before_action :authorize_params, :only => :update

  # yuck! rails' params parsing is broken
  before_action :fix_roles_attributes_params, only: [:create, :update]

  # guards_permissions :user

  def index
  end

  def show
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(params[:user])
    @user.memberships.build(:site => @site) if @site and !@user.has_role?(:superuser)

    if @user.save
      @user.verify! # TODO hu??
      trigger_events(@user)
      flash[:notice] = t(:'adva.users.flash.create.success')
      redirect_to admin_user_url(@site, @user)
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
      redirect_to admin_user_url(@site, @user)
    else
      flash.now[:error] = t(:'adva.users.flash.update.failure')
      render :action => :edit
    end
  end

  def destroy
    if @user.destroy
      trigger_events(@user)
      flash[:notice] = t(:'adva.users.flash.destroy.success')
      redirect_to admin_users_url(@site)
    else
      flash.now[:error] = t(:'adva.users.flash.destroy.failure')
      render :action => :edit
    end
  end

  private

  def fix_roles_attributes_params
    # yuck! rails' params parsing is broken
    params[:user][:roles_attributes] = params[:user][:roles_attributes].to_unsafe_hash.map { |key, value| value } if params[:user][:roles_attributes]
  end

    def set_menu
      @menu = Menus::Admin::Users.new
    end

    def set_users
      @users = @site ? @site.users_and_superusers :
                       User.admins_and_superusers
    end

    def set_user
      @user = User.find(params[:id])
    end

    # FIXME extract this and use Rbac contexts instead
    def authorize_access
      redirect_to admin_sites_url unless @site || current_user.has_role?(:superuser)
    end

    def authorize_params
      return
      return unless params[:user] && params[:user][:roles]

      if params[:user][:roles].has_key?('superuser') && !current_user.has_role?(:superuser) ||
         params[:user][:roles].has_key?('admin') && !current_user.has_role?(:admin, @site)
        raise "unauthorized parameter" # TODO raise something more meaningful
      end
      # TODO as well check for membership site_id if !user.has_role?(:superuser)
    end
end
