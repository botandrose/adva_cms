module BaseHelper
  def column(&block)
    content_tag(:div, class: "col", &block)
  end

  def buttons(&block)
    content_tag(:p, class: "buttons", &block)
  end

  def split_form_for(record, options = {}, &block)
    html_options = options.delete(:html) || {}
    url = options.delete(:url) || polymorphic_path(record)
    as = options.delete(:as)
    method = html_options.delete(:method) || (record.respond_to?(:persisted?) && record.persisted? ? :patch : :post)
    multipart = html_options.delete(:multipart)
    html_options[:enctype] = "multipart/form-data" if multipart
    content_for :form, form_tag(url, html_options.merge(method: method)).html_safe
    fields_for(as || record, record, options, &block)
  end

  def datetime_with_microformat(datetime, options={})
    return datetime unless datetime.respond_to?(:strftime)
    options.symbolize_keys!
    options[:format] ||= :default
    options[:type]   ||= :time
    # yuck ... use the localized_dates plugin as soon as we're on Rails 2.2?
    # formatted_datetime = options[:format].is_a?(Symbol) ? datetime.clone.in_time_zone.to_s(options[:format]) : datetime.clone.in_time_zone.strftime(options[:format])
    formatted_datetime = l(datetime.in_time_zone.send(options[:type].to_sym == :time ? :to_time : :to_date), format: options[:format])

    %{<abbr class="datetime" title="#{datetime.utc.xmlschema}">#{formatted_datetime}</abbr>}.html_safe
  end

  def filter_options
    FilteredColumn.filters.keys.inject([]) do |arr, key|
      arr << [FilteredColumn.filters[key].filter_name, key.to_s]
    end.unshift ["Plain HTML", ""]
  end

  def author_options(users)
    authors = [[current_user.name, current_user.id]]
    authors += users.map { |author| [author.name, author.id] }
    authors.uniq
  end

  def author_selected(content = nil)
    # FIXME why would we want to preselect the previous author of the
    #       content when we are editing it?
    # content.try(:author_id) || current_user.id
    current_user.id
  end

  def link_path(section, link, *args)
    link.body
  end
end
