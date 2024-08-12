class ArticlesController < BaseController
  def index
    @article = articles.first
    if !@article
      raise ActiveRecord::RecordNotFound
    else
      show
    end
  end

  def show
    @article ||= section.articles.find_by_permalink!(params[:permalink])
    if @article.draft?
      raise ActiveRecord::RecordNotFound unless current_user.admin?
    end
    return redirect_to @article.body if @article.is_a?(Link)

    if stale?([*@article.cells, @article, section, site], public: true)
      render template: "#{section.type.tableize}/articles/show"
    end
  end

  private

  helper_method def articles
    @articles ||= begin
      scope = category ? category.all_contents : section.contents
      scope = scope.tagged(tags) if tags.any?
      scope = scope.published
      scope.paginate(page: current_page).limit(section.contents_per_page.to_i)
    end
  end

  helper_method def category
    if !defined?(@category)
      @category = params[:category_id] ? section.categories.find(params[:category_id]) : nil
    end
    @category
  end

  helper_method def tags
    return @tags if defined?(@tags)
    names = params[:tags].to_s.split('+')
    @tags = Tag.where(name: names).pluck(:name)
    raise ActiveRecord::RecordNotFound if @tags.size != names.size
    @tags
  end

  helper_method def current_resource
    section.try(:single_article_mode) ? section : @article || section
  end
end
