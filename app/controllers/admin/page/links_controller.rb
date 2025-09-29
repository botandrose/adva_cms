class Admin::Page::LinksController < Admin::BaseController
  default_param :link, :author_id, :only => [:create, :update], &lambda { |*| current_user.id }

  before_action :set_section
  before_action :set_link,    :only => [:show, :edit, :update, :destroy]

  def new
    @link = @section.links.build(link_params)
  end

  def edit
  end

  def create
    @link = @section.links.build(link_params)
    if @link.save
      trigger_events(@link)
      redirect_to [:edit, :admin, @section, @link], notice: "The link has been created."
    else
      flash.now.alert = "The link could not be created." + current_resource_errors
      render :action => 'new'
    end
  end

  def update
    if @link.update(link_params)
      trigger_events(@link)
      redirect_to [:edit, :admin, @section, @link], notice: "The link has been updated."
    else
      flash.now.alert = "The link could not be updated." + current_resource_errors
      render :action => 'edit', :cl => content_locale
    end
  end

  def destroy
    if @link.destroy
      trigger_events(@link)
      redirect_to [:admin, @section, :contents], notice: "The link has been deleted."
    else
      flash.now.alert = "The link could not be deleted." + current_resource_errors
      render :action => 'edit'
    end
  end

  protected

    def current_resource
      @link || @section
    end

    def set_menu
      @menu = Menus::Admin::Links.new
    end

    def set_link
      @link = @section.links.find_by_permalink! params[:id]
    end

    def link_params
      return {} unless params[:link]
      params.require(:link).permit(:title, :body, :author_id, :permalink)
    end
end
