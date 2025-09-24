class Admin::SitesController < Admin::BaseController
  before_action :params_site, :only => [:new, :create]
  before_action :params_section, :only => [:new, :create]
  before_action :protect_single_site_mode, :only => [:index, :new, :create, :destroy]

  def index
    @sites = Site.paginate(:page => params[:page], :per_page => params[:per_page]).order(:id)
  end

  def show
    @users = @site.users
    @contents = @site.unapproved_comments.group_by(&:commentable) if @site.respond_to?(:unapproved_comments)
    @activities = @site.grouped_activities
  end

  def new
  end

  def create
    site = Site.new site_params
    section = site.sections.build(section_params)
    site.sections << section

    if site.save
      redirect_to admin_site_url(site), notice: "The site has been created."
    else
      flash.now.alert = "The site could not be created"
      render action: :new
    end
  end

  def edit
  end

  def update
    if @site.update site_params
      redirect_to edit_admin_site_url, notice: "The site has been updated."
    else
      flash.now.alert = "The site could not be updated"
      render action: :edit
    end
  end

  def destroy
    if @site.destroy
      redirect_to admin_sites_url, notice: "The site has been deleted."
    else
      flash.now.alert = "The site could not be deleted"
      render action: :show
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

    # For resourceful routes under /admin/sites/:id we must respect :id, not the host.
    def set_site
      @site = params[:id] ? Site.find(params[:id]) : Site.find_by_host!(request.host)
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
      params[:section][:type]  ||= Section.types.first
    end

    def site_params
      return {} unless params[:site]
      params.require(:site).permit(:name, :title, :host, :email, :timezone, :comment_filter)
    end

    def section_params
      return {} unless params[:section]
      params.require(:section).permit(:title, :permalink, :type)
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
