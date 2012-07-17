class BlogArticlesController < ArticlesController
  helper :blog

  def index
    respond_to do |format|
      format.html { render :template => "blogs/articles/index" }
      format.atom { render :template => "blogs/articles/index", :layout => false }
    end
  end

  protected
    def set_articles
      scope = @category ? @category.all_contents : @section.articles
      scope = scope.tagged(@tags) if @tags.present?
      scope = scope.published(params[:year], params[:month])
      @articles = scope.paginate(:page  => current_page, :order => "contents.published_at DESC")
    end

    def valid_article?
      @article and (@article.draft? or @article.published_at?(params.values_at(:year, :month, :day)))
    end
end
