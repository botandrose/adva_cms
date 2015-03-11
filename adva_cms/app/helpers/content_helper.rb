module ContentHelper
  def published_at_formatted(article)
    return t(:'adva.contents.not_published') unless article && article.published?
    l(article.published_at, :format => (article.published_at.year == Time.now.year ? :short : :long))
  end

  # def article_url(section, article, options = {})
  #   if article.section.is_a?(Blog)
  #     blog_article_url(section, article.full_permalink.merge(options))
  #   else
  #     page_article_url(*[section, article.permalink, options].compact)
  #   end
  # end

  def page_link_path section, link
    link.body_html
  end

  def content_path(section, content)
    return article_path(section, content) if content.is_a? Article
    link_path(section, content)
  end

  def content_status(content)
    return "<span>&nbsp;</span>" unless content.respond_to?(:published?)
    klass = content.published? ? 'published' : 'pending'
    text  = content.published? ? t(:'adva.titles.published') : t(:'adva.titles.pending')

    "<span title='#{text}' alt='#{text}' class='status #{klass}'>#{text}</span>"
  end

  def link_to_preview(*args)
    options = args.extract_options!
    content, text = *args.reverse

    text ||= :"adva.#{content.class.name.tableize}.links.preview"
    url = show_path(content, :cl => content.class.locale, :namespace => nil)

    options.reverse_merge!(:url => url, :class => "preview #{content.class.name.underscore}")
    link_to_show(text, content, options)
  end

  def link_to_content(*args)
    options = args.extract_options!
    object, text = *args.reverse
    link_to_show(text || (object.is_a?(Site) ? object.name : object.title), object, options) if object
  end

  def link_to_category(*args)
    text = args.shift if args.first.is_a?(String)
    category = args.pop
    section = args.pop || category.section
    route_name = :"#{section.class.name.downcase}_category_path"
    text ||= category.title
    link_to(text, send(route_name, :section_id => section.id, :category_id => category.id))
  end

  def links_to_content_categories(content, key = nil)
    return if content.categories.empty?
    links = content.categories.map { |category| link_to_category content.section, category }
    key ? t(key, :links => links.join(', ')) : links
  end

  def link_to_tag(*args, &block)
    tag = args.pop
    section = args.pop
    route_name = :"#{section.class.name.downcase}_tag_path"

    if block_given?
      link_to(send(route_name, section_permalink: section.permalink, tags: tag), &block)
    else
      text = args.pop || tag.name
      link_to(text, send(route_name, section_permalink: section.permalink, tags: tag))
    end
  end

  def links_to_content_tags(content, key = nil)
    return if content.tags.empty?
    links = content.tags.map { |tag| link_to_tag content.section, tag }
    key ? t(key, links: links.join(', ')).html_safe : links
  end

  def content_category_checkbox(content, category)
    type = content.type.downcase
    checked = content.categories.include?(category)
    name = "#{type}[category_ids][]"
    id = "#{type}_category_#{category.id}"
    check_box_tag(name, category.id, checked, :id => id)
  end
end
