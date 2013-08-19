Rails.application.routes.draw do
  get "login" => "session#new"
  delete "logout" => "session#destroy"

  resource :session,     :controller => "session"
  resource :password,    :controller => "password"

  namespace :admin do
    resources :users
    resources :sites do
      resources :users
    end
  end
end
