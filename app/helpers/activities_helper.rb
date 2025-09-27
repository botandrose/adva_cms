module ActivitiesHelper
  def render_activities(activities, recent = false)
    if activities.present?
      html = activities.collect do |activity|
        render :partial => "admin/activities/#{activity.object_type.downcase}",
               :locals => { :activity => activity, :recent => recent }
      end.join
    else
      html = %(<li class="empty shade">Nothing happened.</li>)
    end
    raw %(<ul class="activities">#{html}</ul>)
  end

  def activity_css_classes(activity)
    type = activity.object_attributes['type'] || activity.object_type
    "#{type}_#{activity.all_actions.last}".downcase
    # activity.all_actions.collect {|action| "#{type}-#{action}".downcase }.uniq * ' '
  end

  def activity_datetime(activity, short = false)
    if activity.from and short
      from = activity.from.to_fs(:time_only)
      to = activity.to.to_fs(:time_only)
      "#{from} - #{to}"
    elsif activity.from and activity.from.to_date != activity.to.to_date
      from = activity.from.to_fs(:long_ordinalized)
      to = activity.to.to_fs(:long_ordinal)
      "#{from} - #{to}"
    elsif activity.from
      from = activity.from.to_fs(:long_ordinal)
      to = activity.to.to_fs(:time_only)
      "#{from} - #{to}"
    else
      activity.created_at.to_fs(short ? :time_only :  :long_ordinal)
    end
  end

  def link_to_activity_user(activity)
    if activity.author.registered?
      link_to activity.author_name, admin_user_path(activity.author)
    else
      activity.author_link(:include_email => true)
    end
  end
end

