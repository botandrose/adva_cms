require "adva/has_permalink"
require "adva/belongs_to_author"

class Content < ActiveRecord::Base
  # Fix STI in dev
  unless Rails.application.config.eager_load
    def self.find_sti_class(type_name)
      eval(type_name.to_s)
    end
  end

  acts_as_nested_set scope: :section_id

  acts_as_taggable_on :tags

  include Adva::HasPermalink
  has_permalink :title, url_attribute: :permalink, sync_url: true, only_when_blank: true, scope: :section_id


  has_cells :body, :excerpt if respond_to?(:has_cells)

  belongs_to :site
  belongs_to :section, touch: true

  include Adva::BelongsToAuthor
  belongs_to_author validate: true

  has_many :asset_assignments # TODO dependent: :delete_all?
  has_many :assets, through: :asset_assignments
  has_many :categorizations, -> { includes(:category) }, as: :categorizable, dependent: :destroy
  has_many :categories, through: :categorizations
  has_many :activities, as: :object

  after_save do
    categories.each(&:touch)
  end

  before_save :prepare_activity
  after_save :log_activity
  after_destroy :log_destroy_activity

  before_validation :set_site

  scope :published, -> {
    where(["contents.published_at IS NOT NULL AND contents.published_at <= ?", Time.zone.now])
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

  before_validation :set_published_at_from_draft

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

    def set_published_at_from_draft
      self.published_at = nil if draft.to_i == 1
    end

    def set_site
      self.site_id = section.site_id if section
    end

  private

    def activity_actions
      actions = []
      if new_record?
        actions << "created"
      else
        actions << "revised" if changed?
        if published_at_changed?
          actions << (published? ? "published" : "unpublished")
        end
      end
      actions
    end

    def activity_object_attributes
      { "title" => title, "type" => self.class.name }
    end

    def prepare_activity
      actions = activity_actions
      @pending_activity = actions.any? ? { actions: actions, object_attributes: activity_object_attributes } : nil
    end

    def log_activity
      return unless @pending_activity
      Activity.create!(
        site: site,
        section: section,
        object: self,
        author: (author if respond_to?(:author)),
        actions: @pending_activity[:actions],
        object_attributes: @pending_activity[:object_attributes],
      )
      @pending_activity = nil
    end

    def log_destroy_activity
      Activity.create!(
        site: site,
        section: section,
        object: self,
        author: (author if respond_to?(:author)),
        actions: ["deleted"],
        object_attributes: activity_object_attributes,
      )
    end
end

