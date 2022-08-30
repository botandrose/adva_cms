Rails.application.routes.draw do
  scope :constraints => lambda { |req| Blog.where(:permalink => req.params[:section_permalink]).exists? } do
    get "/:section_permalink" => "blog_articles#index", :as => :blog
    get "/:section_permalink/categories/:category_id" => "blog_articles#index", :as => :blog_category
    get "/:section_permalink/:year/:month/:day/:permalink" => "blog_articles#show", :constraints => { :year => /\d{4}/, :month => /\d{1,2}/, :day => /\d{1,2}/ }, :as => :blog_article
    get "/:section_permalink/articles/:permalink" => "blog_articles#show", :as => :unpublished_blog_article
    get "/:section_permalink/tags/:tags" => "blog_articles#index", :as => :blog_tag
  end

  namespace :admin do
    resources :blogs do
      scope :module => :blog do
        resources :contents, :articles, :categories do
          put "/", :action => "update_all", :on => :collection
        end
      end
    end
  end

  # map.blog_tag           'blogs/:section_id/tags/:tags/:year/:month',
  #                        :controller   => 'blog_articles',
  #                        :action       => 'index',
  #                        :year => nil, :month => nil,
  #                        :requirements => { :year => /\d{4}/, :month => /\d{1,2}/ },
  #                        :conditions   => { :method => :get }

  # map.category_feed      'blogs/:section_id/categories/:category_id.:format',
  #                        :controller   => 'blog_articles',
  #                        :action       => 'index',
  #                        :conditions   => { :method => :get }

  # map.tag_feed           'blogs/:section_id/tags/:tags.:format',
  #                        :controller   => 'blog_articles',
  #                        :action       => 'index',
  #                        :conditions   => { :method => :get }

  # map.blog_comments      'blogs/:section_id/comments.:format',
  #                        :controller   => 'blog_articles',
  #                        :action       => 'comments',
  #                        :conditions   => { :method => :get }

  # map.blog_article_comments 'blogs/:section_id/:year/:month/:day/:permalink.:format',
  #                        :controller   => 'blog_articles',
  #                        :action       => 'comments',
  #                        :requirements => { :year => /\d{4}/, :month => /\d{1,2}/, :day => /\d{1,2}/ },
  #                        :conditions   => { :method => :get }
end
