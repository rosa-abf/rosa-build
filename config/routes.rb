Rosa::Application.routes.draw do
  # XML RPC
  match 'api/xmlrpc' => 'rpc#xe_index'
  
  devise_for :users, :controllers => {:omniauth_callbacks => 'users/omniauth_callbacks'} do
    get '/users/auth/:provider' => 'users/omniauth_callbacks#passthru'
  end
  
  resources :users do
    resources :groups, :only => [:new, :create, :index]
  end

  resources :event_logs, :only => :index

  #resources :downloads, :only => :index
  match 'statistics/' => 'downloads#index', :as => :downloads
  match 'statistics/refresh' => 'downloads#refresh', :as => :downloads_refresh
  match 'statistics/test_sudo' => 'downloads#test_sudo', :as => :test_sudo_downloads

  resources :categories do
    get :platforms, :on => :collection
  end

  match '/private/:platform_name/*file_path' => 'privates#show'

  match 'build_lists/' => 'build_lists#all', :as => :all_build_lists
  match 'build_lists/:id/cancel/' => 'build_lists#cancel', :as => :build_list_cancel
  
  resources :auto_build_lists, :only => [:index, :create, :destroy]

  resources :personal_repositories, :only => [:show] do
    member do
      get :settings
      get :change_visibility
      get :add_project
      get :remove_project
    end
  end

  resources :platforms do
    resources :private_users, :except => [:show, :destroy, :update]

    member do
      post 'freeze'
      post 'unfreeze'
      get 'clone'
      post 'clone'
      post 'build_all'
    end

    collection do
      get 'easy_urpmi'
      get :autocomplete_user_uname
    end

    resources :products do
      # member do
      #   get :clone
      #   get :build
      # end
      resources :product_build_lists, :only => [:create]
    end

    resources :repositories

    resources :categories, :only => [:index, :show]
  end

  resources :projects do
    resource :repo, :controller => "git/repositories", :only => [:show]
    resources :build_lists, :only => [:index, :show] do
      collection do
        get :recent
        post :filter
      end
      member do
        post :publish
      end
    end

    resources :collaborators, :only => [:index, :edit, :update] do
      collection do
        get :edit
        post :update
      end
      member do
        post :update
      end
    end
#    resources :groups, :controller => 'project_groups' do
#    end

    member do
      get :build
      post :process_build
      post :fork
    end
    collection do
      get :auto_build
    end
  end

  resources :repositories do
    member do
      get :add_project
      get :remove_project
    end
  end

  resources :groups do
    resources :members, :only => [:index, :edit, :update] do
      collection do
        get :edit
        post :update
      end
      member do
        post :update
      end
    end
  end

  resources :users, :groups do
    resources :platforms, :only => [:new, :create]

    resources :projects, :only => [:new, :create, :index]

    resources :repositories, :only => [:new, :create]
  end

  match '/catalogs', :to => 'categories#platforms', :as => :catalogs

  match 'build_lists/status_build', :to => "build_lists#status_build"
  match 'build_lists/post_build', :to => "build_lists#post_build"
  match 'build_lists/pre_build', :to => "build_lists#pre_build"
  match 'build_lists/circle_build', :to => "build_lists#circle_build"
  match 'build_lists/new_bbdt', :to => "build_lists#new_bbdt"

  match 'product_status', :to => 'product_build_lists#status_build'

  # Tree
  match '/projects/:project_id/git/tree/:treeish(/*path)', :controller => "git/trees", :action => :show, :treeish => /[0-9a-zA-Z_.\-]*/, :defaults => { :treeish => :master }, :as => :tree
         
  # Commits
  match '/projects/:project_id/git/commits/:treeish(/*path)', :controller => "git/commits", :action => :index, :treeish => /[0-9a-zA-Z_.\-]*/, :defaults => { :treeish => :master }, :as => :commits
  match '/projects/:project_id/git/commit/:id(.:format)', :controller => "git/commits", :action => :show, :defaults => { :format => :html }, :as => :commit
         
  # Blobs
  match '/projects/:project_id/git/blob/:treeish/*path', :controller => "git/blobs", :action => :show, :treeish => /[0-9a-zA-Z_.\-]*/, :defaults => { :treeish => :master }, :as => :blob
  match '/projects/:project_id/git/commit/blob/:commit_hash/*path', :controller => "git/blobs", :action => :show, :project_name => /[0-9a-zA-Z_.\-]*/, :as => :blob_commit
         
  # Blame
  match '/projects/:project_id/git/blame/:treeish/*path', :controller => "git/blobs", :action => :blame, :treeish => /[0-9a-zA-Z_.\-]*/, :defaults => { :treeish => :master }, :as => :blame
  match '/projects/:project_id/git/commit/blame/:commit_hash/*path', :controller => "git/blobs", :action => :blame, :as => :blame_commit
         
  # Raw  
  match '/projects/:project_id/git/raw/:treeish/*path', :controller => "git/blobs", :action => :raw, :treeish => /[0-9a-zA-Z_.\-]*/, :defaults => { :treeish => :master }, :as => :raw
  match '/projects/:project_id/git/commit/raw/:commit_hash/*path', :controller => "git/blobs", :action => :raw, :as => :raw_commit

  root :to => "platforms#index"
  match '/forbidden', :to => 'platforms#forbidden', :as => 'forbidden'
end
