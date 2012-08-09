class Admin::Page::LinksController < Admin::BaseController
  default_param :link, :author_id, :only => [:create, :update], &lambda { current_user.id }

  before_filter :set_section
  before_filter :set_links,   :only => [:index]
  before_filter :set_link,    :only => [:show, :edit, :update, :destroy]

  def new
    @link = @section.links.build params[:link] || {}
  end

  def edit
  end

  def create
    @link = @section.links.build params[:link]
    if @link.save
      trigger_events(@link)
      flash[:notice] = t(:'adva.links.flash.create.success')
      redirect_to [:edit, :admin, @site, @section, @link]
    else
      set_categories
      flash.now[:error] = t(:'adva.links.flash.create.failure')
      render :action => 'new'
    end
  end

  def update
    params[:link][:version].present? ? rollback : update_attributes
  end

  def update_attributes
    @link.attributes = params[:link]

    if save_with_revision? ? @link.save : @link.save_without_revision
      trigger_events(@link)
      flash[:notice] = t(:'adva.links.flash.update.success')
      redirect_to [:edit, :admin, @site, @section, @link]
    else
      set_categories
      flash.now[:error] = t(:'adva.links.flash.update.failure')
      render :action => 'edit', :cl => content_locale
    end
  end

  def rollback
    version = params[:link][:version].to_i

    if @link.version != version and @link.revert_to(version)
      trigger_event(@link, :rolledback)
      flash[:notice] = t(:'adva.links.flash.rollback.success', :version => version)
    else
      flash[:error] = t(:'adva.links.flash.rollback.failure', :version => version)
    end
    redirect_to [:edit, :admin, @site, @section, @link]
  end

  def destroy
    if @link.destroy
      trigger_events(@link)
      flash[:notice] = t(:'adva.links.flash.destroy.success')
      redirect_to [:admin, @site, @section, :contents]
    else
      set_categories
      flash.now[:error] = t(:'adva.links.flash.destroy.failure')
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

    def set_links
      @links = @section.links.filtered params[:filters]
    end

    def set_link
      @link = @section.links.find_by_permalink! params[:id]
    end
end

