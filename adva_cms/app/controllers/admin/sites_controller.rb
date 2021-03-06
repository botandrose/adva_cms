class Admin::SitesController < Admin::BaseController
  before_action :params_site, :only => [:new, :create]
  before_action :params_section, :only => [:new, :create]
  before_action :protect_single_site_mode, :only => [:index, :new, :create, :destroy]

  guards_permissions :site

  def index
    @sites = Site.paginate(:page => params[:page], :per_page => params[:per_page]).order(:id)
  end

  def show
    @users = @site.users_and_superusers # TODO wanna show only *recent* users here
    @contents = @site.unapproved_comments.group_by(&:commentable) if @site.respond_to?(:unapproved_comments)
    @activities = @site.grouped_activities if defined?(AdvaActivity)
  end

  def new
  end

  def create
    site = Site.new params[:site]
    section = site.sections.build(params[:section])
    site.sections << section

    if site.save
      flash[:notice] = t(:'adva.sites.flash.create.success')
      redirect_to admin_site_url(site)
    else
      flash.now[:error] = t(:'adva.sites.flash.create.failure')
      render :action => :new
    end
  end

  def edit
  end

  def update
    if @site.update params[:site]
      flash[:notice] = t(:'adva.sites.flash.update.success')
      redirect_to edit_admin_site_url
    else
      flash.now[:error] = t(:'adva.sites.flash.update.failure')
      render :action => 'edit'
    end
  end

  def destroy
    if @site.destroy
      flash[:notice] = t(:'adva.sites.flash.destroy.success')
      redirect_to return_from(:site_deleted)
    else
      flash.now[:error] = t(:'adva.sites.flash.destroy.failure')
      render :action => 'show'
    end
  end

  private

    def set_menu
      @menu = case params[:action]
      when 'show'
        Menus::Admin::Sites.new
      when 'edit'
        Menus::Admin::Settings.new
      else
        Menus::Admin::Sites::Main.new
      end
    end

    def set_site
      @site = Site.find params[:id] if params[:id]
    end

    def params_site
      params[:site] ||= {}
      params[:site][:timezone]       ||= Time.zone.name
      params[:site][:host]           ||= request.host_with_port
      params[:site][:email]          ||= current_user.email
      params[:site][:comment_filter] ||= 'smartypants_filter'
    end

    def params_section
      params[:section] ||= {}
      params[:section][:title] ||= 'Home'
      params[:section][:title] ||= Section.types.first
    end

    def protect_single_site_mode
      unless Site.multi_sites_enabled
        if params[:action] == 'index'
          site = Site.first
          redirect_to admin_site_url(site)
        else
          render :action => :multi_sites_disabled, :layout => 'simple'
        end
      end
    end
end
