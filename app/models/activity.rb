require "adva/belongs_to_author"

class Activity < ActiveRecord::Base
  belongs_to :site
  belongs_to :section
  belongs_to :object, :polymorphic => true

  prepend Module.new {
    def method_missing(name, *args)
      attrs = self[:object_attributes]
      return attrs[name.to_s] if attrs && attrs.has_key?(name.to_s)
      super name, *args
    end
  }

  include Adva::BelongsToAuthor
  belongs_to_author

  serialize :actions, coder: YAML
  serialize :object_attributes, coder: YAML

  validates_presence_of :site, :section, :object

  attr_accessor :siblings

  class << self
    def find_coinciding_grouped_by_dates(*dates)
      groups = (1..dates.size).collect{[]}
      activities = find_coinciding #, :include => :user

      # collect activities for the given dates
      activities.each do |activity|
        activity_date = activity.created_at.to_date
        dates.each_with_index {|date, i| groups[i] << activity and break if activity_date == date }
      end

      # remove all found activities from the original resultset
      groups.each{|group| group.each{ |activity| activities.delete(activity) }}

      # push remaining resultset as a group itself (i.e. 'the rest of them')
      groups << activities
    end

    def find_coinciding(options = {})
      activities = order(created_at: :desc).limit(50)
      activities = activities.group_by{|r| "#{r.object_type}#{r.object_id}"}.values
      activities = group_coinciding(activities)
      activities.sort{|a, b| b.created_at <=> a.created_at }
    end

    def group_coinciding(activities, delta = nil)
      activities.inject [] do |chunks, group|
        chunks << group.shift
        group.each do |activity|
          last = chunks.last.siblings.last || chunks.last
          if last.coincides_with?(activity, delta)
            chunks.last.siblings << activity
          else
            chunks << activity
          end
        end
        chunks
      end
    end
  end

  after_initialize do
    @siblings = []
  end

  def coincides_with?(other, delta = nil)
    delta ||= 1.hour
    created_at - other.created_at <= delta.to_i
  end

  # FIXME should be translated!
  def all_actions
    actions = Array(siblings.reverse.map(&:actions).compact.flatten) + self.actions
    previous = nil
    actions.reject! { |action| (action == previous).tap { previous = action } }
    actions
  end

  def from
    siblings.last.created_at if siblings.present?
  end

  def to
    created_at
  end
end
