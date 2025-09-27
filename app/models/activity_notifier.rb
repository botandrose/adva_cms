class ActivityNotifier < ActionMailer::Base
  helper :content

  def new_content_notification(activity, user)
    @activity = activity

    mail(
      to: user.email,
      subject: "[#{activity.site.name} / #{activity.section.title}] " +
        I18n.t(:'adva.activity.notifier.new', :activity => activity.object.class),
      from: "#{activity.site.name} <#{activity.site.email}>"
    )
  end
end