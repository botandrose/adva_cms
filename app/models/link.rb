class Link < Content
  filters_attributes :except => [:excerpt, :excerpt_html, :body, :body_html, :cached_tag_list]
  validates_presence_of :title, :body
end
