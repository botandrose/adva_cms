class Article < Content
  # default_scope :order => "#{self.table_name}.published_at DESC"

  filters_attributes :except => [:excerpt, :excerpt_html, :body, :body_html, :cached_tag_list]

  validates_presence_of :title, :body
  validates_uniqueness_of :permalink, :scope => :section_id

  class << self
    def locale
      "en"
    end
  end

  def primary?
    self == section.articles.primary
  end

  def previous
    section.articles.published.where(["#{self.class.table_name}.published_at < ?", published_at]).reorder(published_at: :desc).first
  end
  alias_method :previous_article, :previous

  def next
    section.articles.published.where(["#{self.class.table_name}.published_at > ?", published_at]).reorder(published_at: :asc).first
  end
  alias_method :next_article, :next

  def has_excerpt?
    return false if excerpt == "<p>&#160;</p>" # empty excerpt with fckeditor
    excerpt.present?
  end

  def full_permalink
    raise "cannot create full_permalink for an article that belongs to a non-blog section" unless section.is_a?(Blog)
    # raise "can not create full_permalink for an unpublished article" unless published?
    date = [:year, :month, :day].map { |key| [key, (published? ? published_at : created_at).send(key)] }.flatten
    Hash[:permalink, permalink, *date]
  end
end
