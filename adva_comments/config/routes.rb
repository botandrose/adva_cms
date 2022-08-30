Rails.application.routes.draw do
  resources :comments, :except => :index do
    post :preview, :on => :collection
  end

  namespace :admin do
    resources :comments
  end
end
