require "adva/has_permalink"
require "adva/belongs_to_author"

class Content < ActiveRecord::Base
  acts_as_nested_set :scope => :section_id

  # TODO is this needed?
  class Version < ActiveRecord::Base
    filters_attributes :none => true
  end

  has_filter :tagged, :categorized,
             :text  => { :attributes => [:title, :body, :excerpt] },
             :state => { :states => [:published, :unpublished] }

  acts_as_taggable

  include Adva::HasPermalink
  has_permalink :title, :url_attribute => :permalink, :sync_url => true, :only_when_blank => true, :scope => :section_id

  filtered_column :body, :excerpt

  belongs_to :site
  belongs_to :section, :touch => true

  include Adva::BelongsToAuthor
  belongs_to_author :validate => true

  has_many :asset_assignments # TODO :dependent => :delete_all?
  has_many :assets, :through => :asset_assignments
  has_many :categorizations, -> { includes(:category) }, as: :categorizable, dependent: :destroy
  has_many :categories, :through => :categorizations
  has_many :activities, :as => :object

  after_save do
    categories.each(&:touch)
  end

  before_validation :set_site

  scope :published, -> {
    where(['contents.published_at IS NOT NULL AND contents.published_at <= ?', Time.zone.now])
  }

  scope :drafts, -> {
    where(published_at: nil)
  }

  scope :unpublished, -> {
    drafts
  }

  scope :by_category, -> (category) {
    section_type = category.section.class
    includes([:categories, :section])
      .where([
        "categories.lft >= ? AND categories.rgt <= ? AND sections.type = ?",
        category.lft, category.rgt, section_type.to_s
      ]).references(:categories, :section)
  }

  class << self
    def primary
      published.first
    end
  end

  def to_param
    permalink
  end

  def cache_key(*timestamp_names)
    if new_record?
      "#{model_name.cache_key}/new"
    else
      timestamp_names = [:updated_at, :cells_updated_at] if timestamp_names.none?
      timestamp = timestamp_names.map { |attr| send(attr) }.compact.map(&:to_time).max
      timestamp = timestamp.utc.to_s(cache_timestamp_format)
      "#{model_name.cache_key}/#{id}-#{timestamp}"
    end
  end

  def cells_updated_at
    if defined?(OutputFilter::Cells)
      OutputFilter::Cells.new(nil).send(:cells, body_html).values.map do |name, state, attrs|
        attrs = HashWithIndifferentAccess.new(attrs)
        cell = "#{name.camelize}Cell".constantize.new
        args = [state]
        attrs.delete "class" # ignore styling class
        attrs[:format] = :timestamp
        args << attrs unless attrs.empty?
        begin
          cell.render_state *args
        rescue ArgumentError
        end
      end.select { |response| response.is_a?(Time) }.max
    end
  end

  def owners
    owner.owners << owner
  end

  def owner
    section
  end

  def category_titles
    categories.collect(&:title)
  end

  attr_accessor :draft
  def published_at=(published_at)
    write_attribute(:published_at, draft.to_i == 1 ? nil : published_at)
  end

  def author_id=(author_id)
    # FIXME this is only needed because belongs_to_cacheable can't be non-polymorphic, yet
    self.author = User.find(author_id) if author_id
  end

  def published_year
    Time.local(published_at.year, 1, 1)
  end

  def published_month
    Time.local(published_at.year, published_at.month, 1)
  end

  def draft?
    published_at.nil?
  end

  def pending?
    !published?
  end

  def published?
    !published_at.nil? && published_at <= Time.zone.now
  end

  def published_at?(date)
    published? && date == [:year, :month, :day].map { |key| published_at.send(key).to_s }
  end

  def state
    pending? ? :pending : :published
  end

  def just_published?
    published? && published_at_changed?
  end

  # def to_param(key)
  #   value = if self.respond_to?(key)
  #     self.send(key)
  #   elsif [:year, :month, :day].include?(key)
  #     published_at.send(key)
  #   else
  #     super()
  #   end
  #   value ? value.to_s : nil
  # end

  protected

    def set_site
      self.site_id = section.site_id if section
    end

    def update_categories(category_ids)
      category_ids = Array(category_ids).reject(&:blank?)
      return if category_ids.empty?

      categories.each do |category|
        category_ids.delete(category.id.to_s) || categories.delete(category)
      end
      if category_ids.present?
        categories << Category.find(:all, :conditions => ['id in (?)', category_ids])
      end
    end
end
