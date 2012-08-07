class Admin::Blog::ArticlesController < Admin::Page::ArticlesController
  def index
    @contents = @section.articles
  end
end
