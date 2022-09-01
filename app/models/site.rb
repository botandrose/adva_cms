class Site < ActiveRecord::Base
  serialize :permissions
  serialize :spam_options

  has_many :sections, :dependent => :destroy do
    def paths
      map(&:path)
    end

    # FIXME can this be on the nested_set?
    def update_paths!
      paths = Hash[*roots.map { |r|
        r.self_and_descendants.map { |n| [n.id, { 'path' => n.send(:build_path) }] } }.flatten]
      update paths.keys, paths.values
    end
  end

  has_many :memberships, :dependent => :delete_all
  has_many :users, :through => :memberships, :dependent => :destroy
  has_many :cached_pages, -> { order(updated_at: :desc) }, dependent: :destroy
  has_many :activities, :dependent => :destroy

  before_validation :downcase_host, :replace_host_spaces # c'mon, can't this be normalize_host or something?
  before_validation :populate_title

  validates_presence_of :host, :name, :title
  validates_uniqueness_of :host, case_sensitive: true

  cattr_accessor :multi_sites_enabled, :cache_sweeper_logging

  class_attribute :meta_fields, default: %w(keywords description author copyright geourl)

  class << self
    def find_by_host!(host)
      return Site.first if count == 1 && !multi_sites_enabled
      where("? = ANY (hosts)", host).first or raise ActiveRecord::RecordNotFound
    end

    def bust_cache!
      all.each(&:touch)
    end
  end

  def multi_sites_enabled?
    self.class.multi_sites_enabled
  end

  def owners
    []
  end

  def owner
    nil
  end

  def section_ids
    types = Section.types.map { |type| "'#{type}'" }.join(', ')
    self.class.connection.select_values("SELECT id FROM contents WHERE type IN (#{types}) AND site_id = #{id}")
  end

  # def tag_counts
  #   Content.tag_counts :conditions => "site_id = #{id}"
  # end

  def perma_host
    host.sub(':', '.')  # Needed to create valid directories in ms-win
  end

  def grouped_activities
    activities.find_coinciding_grouped_by_dates(Time.zone.now.to_date, 1.day.ago.to_date)
  end

  def plugins
    @plugins ||= Rails.plugins.values.inject(ActiveSupport::OrderedHash.new) do |plugins, plugin|
      plugin = plugin.clone
      plugin.owner = self
      plugins[plugin.name.to_sym] = plugin
      plugins
    end
  end

  def email_from
    "#{name} <#{email}>" unless name.blank? || email.blank?
  end

  private

    def downcase_host
      self.host = host.to_s.downcase
    end

    def replace_host_spaces # err ... maybe name this a tad less implementation oriented?
      self.host = host.to_s.gsub(/^\s+|\s+$/, '').gsub(/\s+/, '-')
    end

    def populate_title
      self.title = self.name if self.title.blank?
    end
end
