module Admin::BaseHelper
  def self.define_shallow_resource_helpers options
    from = options.delete(:from)
    to = options.delete(:to)

    from_namespace = from[0..-2].collect(&:to_s).join("_")
    to_namespace = to[0..-2].collect(&:to_s).join("_")
    resource = from[-1].to_s

    def self.define_path_and_url_methods options
      from = options.delete(:from)
      to = options.delete(:to)

      %w(path url).each do |suffix|
        eval "def #{from}_#{suffix} *args; #{to}_#{suffix} *args; end"
      end
    end

    # index
    define_path_and_url_methods \
      :from => [from_namespace, resource.pluralize].join("_"),
      :to => [to_namespace, resource.pluralize].join("_")

    # show
    define_path_and_url_methods \
      :from => [from_namespace, resource].join("_"),
      :to => [to_namespace, resource].join("_")

    # new
    define_path_and_url_methods \
      :from => [:new, from_namespace, resource].join("_"),
      :to => [:new, to_namespace, resource].join("_")

    # edit
    define_path_and_url_methods \
      :from => [:edit, from_namespace, resource].join("_"),
      :to => [:edit, to_namespace, resource].join("_")
  end

  define_shallow_resource_helpers :from => [:admin, :section], :to => [:admin, :site, :section]

  define_shallow_resource_helpers :from => [:admin, :category], :to => [:admin, :site, :section, :category]
  define_shallow_resource_helpers :from => [:admin, :content], :to => [:admin, :site, :section, :content]
  define_shallow_resource_helpers :from => [:admin, :article], :to => [:admin, :site, :section, :article]
  define_shallow_resource_helpers :from => [:admin, :link], :to => [:admin, :site, :section, :link]


  def save_or_cancel_links(builder, options = {})
    save_text   = options.delete(:save_text)   || t(:'adva.common.save')
    or_text     = options.delete(:or_text)     || t(:'adva.common.connector.or')
    cancel_text = options.delete(:cancel_text) || t(:'adva.common.cancel')
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

  def link_to_profile(site, options = {})
    name = options[:name].nil? ? t(:'adva.links.profile') : options[:name]
    site = nil if site.try(:new_record?)
    path = if site
      admin_site_user_path(site, current_user)
    else
      admin_user_path(current_user)
    end
    link_to(name, path)
  end

  def links_to_content_translations(content, &block)
    return '' if content.new_record?
    block = Proc.new { |locale| link_to_edit(locale, content, :cl => locale) } unless block
    locales = content.translated_locales.map { |locale| block.call(locale.to_s) }
    content_tag(:span, :class => 'content_translations') do
      t(:"adva.#{content[:type].tableize}.translation_links", :locales => locales.join(', ')) +
      "<p class=\"hint\" for=\"content_translations\">#{t(:'adva.hints.content_translations')}</p>"
    end
  end

  def link_to_clear_cached_pages(site)
    link_to(t(:'adva.cached_pages.links.clear_all'), admin_cached_pages_path(site), :method => :delete)
  end

  def link_to_restore_plugin_defaults(site, plugin)
    link_to(t(:'adva.titles.restore_defaults'), admin_plugin_path(site, plugin), :data => { :confirm => t(:'adva.plugins.confirm_reset') })
  end

  # FIXME: translations
  def page_cached_at(page)
    if Date.today == page.updated_at.to_date
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
