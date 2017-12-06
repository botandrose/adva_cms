atom_feed :url => request.url do |feed|
  title = "#{@site.title} » #{@section.title}"

  title = title + " » " + t( :'adva.blog.feeds.category', :category => @category.title ) if @category
  title = title + " » " + t( :'adva.blog.feeds.tags', :tags => @tags.join(', '), :count => @tags.size ) if @tags.present?

  feed.title title
  feed.updated @articles.first ? @articles.first.updated_at : Time.now.utc

  @articles[0..12].each do |article|
    url = [request.protocol, @site.host, url_for([@section, article])].join("")
    feed.entry article, :url => url do |entry|
      entry.title article.title
      entry.content "#{absolutize_links(article.excerpt_html)} #{absolutize_links(article.body_html)}", :type => 'html'
      entry.author do |author|
        author.name article.author_name
        author.email article.author_email
      end
    end
  end
end
