# -*- encoding : utf-8 -*-
Rosa::Application.routes.draw do
  # XML RPC
  match 'api/xmlrpc' => 'rpc#xe_index'

  devise_for :users, :controllers => {:omniauth_callbacks => 'users/omniauth_callbacks'} do
    get '/users/auth/:provider' => 'users/omniauth_callbacks#passthru'
  end

  resources :users do
    resources :groups, :only => [:new, :create, :index]
    get :autocomplete_user_uname, :on => :collection
    namespace :settings do
      resource :notifier, :only => [:show, :update]
    end
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

  match 'build_lists/publish_build', :to => "build_lists#publish_build"
  match 'build_lists/status_build', :to => "build_lists#status_build"
  match 'build_lists/post_build', :to => "build_lists#post_build"
  match 'build_lists/pre_build', :to => "build_lists#pre_build"
  match 'build_lists/circle_build', :to => "build_lists#circle_build"
  match 'build_lists/new_bbdt', :to => "build_lists#new_bbdt"

  resources :build_lists, :only => [:index, :show] do
    member do
      put :cancel
      put :publish
    end
  end

  post 'build_lists' => 'build_lists#index', :as => 'build_lists'

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
    resources :wiki do
      collection do
        match '_history' => 'wiki#wiki_history', :as => :history, :via => :get
        match '_access' => 'wiki#git', :as => :git, :via => :get
        match '_revert/:sha1/:sha2' => 'wiki#revert_wiki', :as => :revert, :via => [:get, :post]
        match '_compare' => 'wiki#compare_wiki', :as => :compare, :via => :post
        match '_compare/*versions' => 'wiki#compare_wiki', :as => :compare_versions, :via => :get
        post :preview
        get :search
        get :pages
      end
      member do
        get :history
        get :edit
        match 'revert/:sha1/:sha2' => 'wiki#revert', :as => :revert_page, :via => [:get, :post]
        match ':ref' => 'wiki#show', :as => :versioned, :via => :get

        post :compare
        match 'compare/*versions' => 'wiki#compare', :as => :compare_versions, :via => :get
      end
    end
    resources :issues do
      resources :comments, :only => [:edit, :create, :update, :destroy]
      resources :subscribes, :only => [:create, :destroy]
    end
    resource :repo, :controller => "git/repositories", :only => [:show]
    resources :build_lists, :only => [:index, :new, :create]

    resources :collaborators, :only => [:index, :edit, :update, :add] do
      collection do
        get :edit
        post :update
        post :add
      end
      member do
        post :update
      end
    end
#    resources :groups, :controller => 'project_groups' do
#    end

    member do
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
      get :projects_list
    end
  end

  resources :groups do
    get :autocomplete_group_uname, :on => :collection
    resources :members, :only => [:index, :edit, :update, :add] do
      collection do
        get  :edit
        post :add
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

#    resources :repositories, :only => [:new, :create]
  end

  match '/catalogs', :to => 'categories#platforms', :as => :catalogs

  match 'product_status', :to => 'product_build_lists#status_build'

  # Tree
  match '/projects/:project_id/git/tree/:treeish(/*path)', :controller => "git/trees", :action => :show, :treeish => /[0-9a-zA-Z_.\-]*/, :defaults => { :treeish => :master }, :as => :tree

  # Commits
  match '/projects/:project_id/git/commits/:treeish(/*path)', :controller => "git/commits", :action => :index, :treeish => /[0-9a-zA-Z_.\-]*/, :defaults => { :treeish => :master }, :as => :commits
  match '/projects/:project_id/git/commit/:id(.:format)', :controller => "git/commits", :action => :show, :defaults => { :format => :html }, :as => :commit
  # Commit Comments
  match '/projects/:project_id/git/commit/:commit_id/comments/:id(.:format)', :controller => "comments", :action => :edit, :as => :edit_project_commit_comment, :via => :get
  match '/projects/:project_id/git/commit/:commit_id/comments/:id(.:format)', :controller => "comments", :action => :update, :as => :project_commit_comment, :via => :put
  match '/projects/:project_id/git/commit/:commit_id/comments/:id(.:format)', :controller => "comments", :action => :destroy, :via => :delete
  match '/projects/:project_id/git/commit/:commit_id/comments(.:format)', :controller => "comments", :action => :create, :as => :project_commit_comments, :via => :post
  # Commits subscribe
  match '/projects/:project_id/git/commit/:commit_id/subscribe', :controller => "commit_subscribes", :action => :create, :defaults => { :format => :html }, :as => :subscribe_commit, :via => :post
  match '/projects/:project_id/git/commit/:commit_id/unsubscribe', :controller => "commit_subscribes", :action => :destroy, :defaults => { :format => :html }, :as => :unsubscribe_commit, :via => :delete
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
