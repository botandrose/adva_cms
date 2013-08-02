ActionDispatch::Callbacks.to_prepare do
  Article.class_eval do
    cattr_accessor :meta_fields
    self.meta_fields = %w(keywords description author copyright geourl)

    def default_meta_description
      HTML::FullSanitizer.new.sanitize(body).gsub(/\s+/, " ").strip.truncate(160)
    end
  end
end

class ArticleFormBuilder < ExtensibleFormBuilder
  after :article, :tab_options do |f|
    tab :meta_tags do |f|
      render :partial => 'admin/articles/meta_tags', :locals => { :f => f }
    end
  end
end
