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
        put "update_all", :on => :collection

        resources :contents do
          put "update_all", :on => :collection
        end

        resources :articles do
          put "update_all", :on => :collection
        end

        resources :links do
          put "update_all", :on => :collection
        end

        resources :categories do
          put "update_all", :on => :collection
        end
      end

      resources :pages do
        put "update_all", :on => :collection

        resources :contents do
          put "update_all", :on => :collection
        end

        resources :articles do
          put "update_all", :on => :collection
        end

        resources :links do
          put "update_all", :on => :collection
        end

        resources :categories do
          put "update_all", :on => :collection
        end
      end
    end

    resources :cells, :only => :index
  end
end
