Rails.application.routes.draw do
  get "login" => "session#new"
  delete "logout" => "session#destroy"

  get "signup" => "user#new"

  resource :session,     :controller => "session"
  resource :password,    :controller => "password"
  resource :user,        :controller => "user" do
    get "verify", :on => :member
    get "verification_sent", :on => :collection
  end

  namespace :admin do
    resources :users
    resources :sites do
      resources :users
    end
  end
end
