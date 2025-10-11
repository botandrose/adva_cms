class Admin::Page::ArticlesController < Admin::BaseController
  default_param :article, :author_id, :only => [:create, :update], &lambda { |*| current_user.id }

  before_action :set_section
  before_action :protect_single_article_mode
  before_action :set_article,    :only => [:show, :edit, :update, :destroy]
  before_action :set_categories, :only => [:new, :edit]
  before_action :optimistic_lock, :only => :update
  
  after_action :clear_static_cache, :only => [:create, :update, :update_all, :destroy]

  def index
    redirect_to [:admin, @section, :contents]
  end

  def show
    @article.revert_to(params[:version]) if params[:version]
    render :template => "#{@section.type.tableize}/articles/show", layout: 'application'
  end

  def new
    defaults = { :comment_age => @section.comment_age, :filter => @section.content_filter }
    @article = @section.articles.build(defaults.update(params[:article] || {}))
  end

  def edit
  end

  def create
    @article = @section.articles.build(article_params)
    if @article.save
      trigger_events(@article)
      redirect_to [:edit, :admin, @section, @article], notice: "The article has been created."
    else
      set_categories
      flash.now.alert = "The article could not be created." + current_resource_errors
      render :action => 'new'
    end
  end
  
  def update
    if @article.update(article_params)
      trigger_events(@article)
      redirect_to [:edit, :admin, @section, @article], notice: "The article has been updated."
    else
      set_categories
      flash.now.alert = "The article could not be updated." + current_resource_errors
      render :action => 'edit'
    end
  end

  def destroy
    if @article.destroy
      trigger_events(@article)
      redirect_to [:admin, @section, :contents], notice: "The article has been deleted."
    else
      set_categories
      flash.now.alert = "The article could not be deleted." + current_resource_errors
      render :action => 'edit'
    end
  end

  protected

    def current_resource
      @article || @section
    end

    def set_menu
      @menu = Menus::Admin::Articles.new
    end

    def set_article
      @article = @section.articles.find_by_permalink!(params[:id])
    end

    def set_categories
      @categories = @section.categories.roots
    end

    def protect_single_article_mode
      if params[:action] == 'index' && @section.try(:single_article_mode)
        redirect_to @section.articles.empty? ?
          new_admin_page_article_url(@section, :article => { :title => @section.title }) :
          edit_admin_page_article_url(@section, @section.articles.first)
      end
    end

    def optimistic_lock
      return unless updated_at = params.dig(:article, :updated_at)

      if @article.updated_at && (Time.zone.parse(updated_at) != Time.zone.parse(@article.updated_at.to_s))
        flash.now.alert = "In the meantime this article has been updated by someone else. Please resolve any conflicts."
        render :action => :edit
      end
    end

    def clear_static_cache
      @site.touch
    end

    def article_params
      return {} unless params[:article]
      params.require(:article).permit(:title, :body, :author_id, :published_at, :draft, :excerpt, :filter, :tag_list, :updated_at, :permalink)
    end

end
