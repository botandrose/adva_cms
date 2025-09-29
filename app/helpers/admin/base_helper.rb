module Admin::BaseHelper
  def save_or_cancel_links(builder, options = {})
    save_text   = options.delete(:save_text)   || "Save"
    or_text     = options.delete(:or_text)     || "or"
    cancel_text = options.delete(:cancel_text) || "Cancel"
    cancel_url  = options.delete(:cancel_url)

    save_options = options.delete(:save) || {}
    save_options.reverse_merge!(:id => 'commit')
    cancel_options = options.delete(:cancel) || {}

    builder.buttons do
      ''.html_safe.tap do |buttons|
        buttons << submit_tag(save_text, save_options)
        buttons << " #{or_text} #{link_to(cancel_text, cancel_url, cancel_options)}".html_safe if cancel_url
      end
    end.html_safe
  end

  def link_to_profile(options = {})
    name = options[:name].nil? ? "Profile" : options[:name]
    path = admin_user_path(current_user)
    link_to(name, path)
  end

  # FIXME: translations
  def page_cached_at(page)
    if page.updated_at >= Time.current.beginning_of_day
      if page.updated_at > Time.zone.now - 4.hours
        "#{time_ago_in_words(page.updated_at).gsub(/about /,'~ ')} ago"
      else
        "Today, #{page.updated_at.strftime('%l:%M %p')}"
      end
    else
      page.updated_at.strftime("%b %d, %Y")
    end
  end

  def editor_class_for content
    "big wysiwyg"
  end
end
