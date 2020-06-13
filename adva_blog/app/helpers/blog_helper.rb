module BlogHelper
  def articles_title(*args)
    options = args.extract_options!
    category, tags, month = *args
    month = archive_month(month) if month && !month.is_a?(Time)

    title = []
    title << t(:'adva.blog.titles.date', :date => l(month, :format => '%B %Y')) if month
    title << t(:'adva.blog.titles.about', :category => category.title) if category
    title << t(:'adva.blog.titles.tags', :tags => tags.to_sentence) if tags
    
    if title.present?
      title = t(:'adva.blog.titles.articles', :articles => title.join(', ')) 
      options[:format] ? raw(options[:format]) % title : title
    end
  end

  def archive_month(params = {})
    Time.local(params[:year], params[:month]) if params[:year]
  end

  def blog_article_path section, article, options={}
    if article.published_at
      super :section_permalink => section.permalink,
        :year => article.published_at.year,
        :month => article.published_at.month,
        :day => article.published_at.day,
        :permalink => article.permalink
    else
      unpublished_blog_article_path section, article
    end
  end

  def blog_article_url section, article, options={}
    if article.published_at
      super :section_permalink => section.permalink,
        :year => article.published_at.year,
        :month => article.published_at.month,
        :day => article.published_at.day,
        :permalink => article.permalink
    else
      unpublished_blog_article_url section, article
    end
  end

  def absolutize_links html
    html.gsub /(href|src)="\//, %(\\1="http://#{@site.host}/)
  end
end
