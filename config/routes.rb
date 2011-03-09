Rosa::Application.routes.draw do
  devise_for :users

  root :to => "platforms#index"
end
