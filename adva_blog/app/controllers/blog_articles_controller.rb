class BlogArticlesController < ArticlesController
  def index
    if skip_caching? or stale?(:etag => @section, :last_modified => [@articles.to_a, @section, @site].flatten.collect(&:updated_at).compact.max.utc, :public => true)
      respond_to do |format|
        format.html { render :template => "blogs/articles/index" }
        format.atom { render :template => "blogs/articles/index", :layout => false }
      end
    end
  end

  protected
    def set_articles
      scope = @category ? @category.all_contents : @section.articles
      scope = scope.tagged("'#{@tags}'") if @tags.present?
      scope = scope.published # (params[:year], params[:month])
      scope = scope.includes(:approved_comments_counter) if defined?(Comment)
      @articles = scope.paginate(page: current_page, per_page: @section.contents_per_page).order(published_at: :desc)
    end

    def valid_article?
      @article and (@article.draft? or @article.published_at?(params.values_at(:year, :month, :day)))
    end
end
