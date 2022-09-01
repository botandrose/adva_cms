class ArticlesController < BaseController
  include ActionController::GuardsPermissions::InstanceMethods
  helper :roles

  before_action :set_section
  before_action :adjust_action
  before_action :set_category, :only => :index
  before_action :set_tags,     :only => :index
  before_action :set_articles, :only => :index
  before_action :set_article,  :only => :show
  before_action :guard_view_permissions, :only => [:index, :show]

  authenticates_anonymous_user

  def index
    @article = @articles.first
    if !@article
      raise ActiveRecord::RecordNotFound
    elsif @article.is_a?(Link)
      redirect_to @article.body
    else
      show
    end
  end

  def show
    if stale?(etag: [@article, @section, @site], last_modified: [@article, @section, @site].map(&:updated_at).compact.max, public: true)
      render template: "#{@section.type.tableize}/articles/show"
    end
  end

  protected

    def current_resource
      @section.try(:single_article_mode) ? @section : @article || @section
    end

    # adjusts the action from :index to :show when the current section is in single-article mode ...
    def adjust_action
      if params[:action] == 'index' and @section.try(:single_article_mode)
        # ... but only if there is one published article
        unless @section.contents.blank? || (@section.contents.first.draft? && !has_permission?('update', 'section'))
          @action_name = @_params[:action] = request.parameters['action'] = 'show'
        end
      end
    end

    def set_article
      @article = if params[:permalink]
        @section.contents.includes(:author).find_by_permalink!(params[:permalink])
      elsif @section.try(:single_article_mode)
        @section.contents.first
      end
    end

    def set_articles
      scope = @category ? @category.all_contents : @section.contents
      scope = scope.tagged(@tags) if @tags.present?
      scope = scope.published
      @articles = scope.paginate(page: current_page).limit(@section.contents_per_page)
    end

    def set_category
      if params[:category_id]
        @category = @section.categories.find(params[:category_id])
        raise ActiveRecord::RecordNotFound unless @category
      end
    end

    def set_tags
      if params[:tags]
        names = params[:tags].split('+')
        @tags = Tag.where(name: names).pluck(:name)
        raise ActiveRecord::RecordNotFound unless @tags.size == names.size
      end
    end

    def guard_view_permissions
      if @article && @article.draft?
        raise ActiveRecord::RecordNotFound unless has_permission?('update', 'article')
      end
    end
end
