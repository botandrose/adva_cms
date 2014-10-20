class Blog < Section  
  has_many :articles, -> { order("contents.published_at DESC") }, :foreign_key => 'section_id', :dependent => :destroy do
    def permalinks
      published.map(&:permalink)
    end
  end
  alias_method :contents, :articles

  class << self
    def content_types
      %w(Article)
    end
  end

  def archive_months
    article_counts_by_month.transpose.first
  end

  def article_counts_by_month
    articles_by_month.map{|month, articles| [month, articles.size]}
  end

  def articles_by_year
    @articles_by_year ||= articles.published.group_by(&:published_year)
  end

  def articles_by_month
    @articles_by_month ||= articles.published.group_by(&:published_month)
  end

  def nav_children
    categories.roots
  end
end
