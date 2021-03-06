module MetaTagsHelper
  DEFAULT_FIELDS = %w(author geourl copyright keywords description)

  def meta_tags(resource=nil)
    current_resource = controller.try(:current_resource)
    resources = [resource, current_resource, @site].compact

    # TODO: check if we actually need this fallback
    # fields = resource.class.try(:meta_fields) || DEFAULT_FIELDS

    DEFAULT_FIELDS.map do |name|
      resource = resources.find do |r|
        r.respond_to?(:"meta_#{name}")
      end

      if resource
        content = meta_value_from(resource.send(:"meta_#{name}"), resource.try(:"default_meta_#{name}"))
        meta_tag(name, content)
      end
    end.join("\n").html_safe
  end

  def meta_tag(name, content)
    tag 'meta', :name => name, :content => content
  end

  def meta_value_from(*args)
    args.detect { |arg| arg.present? }
  end
end
