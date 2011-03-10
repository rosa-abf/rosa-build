Rosa::Application.routes.draw do
  devise_for :users

  resources :platforms do
    resources :projects do
      resource :git
    end 
  end

  resources :users

  root :to => "platforms#index"
end
