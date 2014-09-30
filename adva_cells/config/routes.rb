Rails.application.routes.draw do
  namespace :admin do
    get "cells" => "cells#index"
  end
end

