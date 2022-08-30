class Admin::Blog::ContentsController < Admin::Page::ContentsController
  def index
    redirect_to [:admin, @section, :articles]
  end
end
