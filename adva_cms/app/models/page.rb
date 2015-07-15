class Page < Section
  has_option :single_article_mode, :default => true, :type => :boolean

  # avoid double destroy hook
  has_many :articles, -> { order(:lft) }, dependent: :destroy, foreign_key: :section_id
  has_many :links, -> { order(:lft) }, dependent: :destroy, foreign_key: :section_id

  class << self
    def content_types
      %w(Article Link)
    end
  end

  def published_at
    return contents.first.published_at if single_article_mode && contents.first
    super
  end

  def published_at=(published_at)
    if single_article_mode && contents.first
      contents.first.update_attribute(:published_at, published_at)
    else
      super
    end
  end

  def published?(parents = false)
    if single_article_mode
      # FIXME: duplication with Section class
      return true if self == site.sections.root
      return false if parents && !ancestors.reject(&:published?).empty?
      return contents.first ? contents.first.published? : false
    end
    super
  end
end
