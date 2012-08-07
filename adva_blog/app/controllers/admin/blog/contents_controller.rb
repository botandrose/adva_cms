class Admin::Blog::ContentsController < Admin::Page::ContentsController
  def index
    redirect_to [:admin, @site, @section, :articles]
  end
end
