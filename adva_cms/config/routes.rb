Rails.application.routes.draw do
  scope :constraints => lambda { |req| Page.where(:permalink => req.params[:section_permalink]).exists? } do
    get "/:section_permalink" => "articles#index", :as => :page
    scope :constraints => lambda { |req| Article.where(:permalink => req.params[:permalink]).exists? } do
      get "/:section_permalink/articles/:permalink" => "articles#show", :as => :page_article
    end
  end

  namespace :admin do
    resources :sites do
      resources :sections do
        put "/", :action => "update_all", :on => :collection
        resources :contents, :articles, :links, :categories do
          put "/", :action => "update_all", :on => :collection
        end
      end

      resources :pages do
        scope :module => :page do
          resources :contents, :articles, :links, :categories do
            put "/", :action => "update_all", :on => :collection
          end
        end
      end
    end

    resources :cells, :only => :index
  end
end
