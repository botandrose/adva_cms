class Page < Section
  has_option :single_article_mode, :default => true, :type => :boolean

  with_options :order => :lft, :foreign_key => 'section_id' do |options|
    options.has_many :contents # avoid double destroy hook
    options.has_many :articles, :dependent => :destroy
    options.has_many :links, :dependent => :destroy
  end

  class << self
    def content_types
      %w(Article Link)
    end
  end

  def published_at
    return articles.first.published_at if single_article_mode && articles.first
    super
  end

  def published_at=(published_at)
    if single_article_mode && articles.first
      articles.first.update_attribute(:published_at, published_at)
    else
      super
    end
  end

  def published?(parents = false)
    if single_article_mode
      # FIXME: duplication with Section class
      return true if self == site.sections.root
      return false if parents && !ancestors.reject(&:published?).empty?
      return articles.first ? articles.first.published? : false
    end
    super
  end
end
