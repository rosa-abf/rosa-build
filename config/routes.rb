# -*- encoding : utf-8 -*-
Rosa::Application.routes.draw do
  # XML RPC
  match 'api/xmlrpc' => 'rpc#xe_index'

  devise_scope :user do
    get '/users/auth/:provider' => 'users/omniauth_callbacks#passthru'
    get '/user' => 'users#profile', :as => 'edit_profile'
    put '/user' => 'users#update', :as => 'update_profile'
    get '/users/:id/edit' => 'users#profile', :as => 'edit_user'
    put '/users/:id/edit' => 'users#update', :as => 'update_user'
  end
  devise_for :users, :controllers => {:omniauth_callbacks => 'users/omniauth_callbacks'}

  resources :users do
    resources :groups, :only => [:new, :create, :index]
    collection do
      resources :register_requests, :only => [:index, :new, :create, :show_message, :approve, :reject] do
        get :show_message, :on => :collection
        put :update,       :on => :collection
        get :approve
        get :reject
      end
      get :autocomplete_user_uname
    end

    namespace :settings do
      resource :notifier, :only => [:show, :update]
    end
  end
  match 'users/:id/settings/private' => 'users#private', :as => :user_private_settings, :via => :get
  match 'users/:id/settings/private' => 'users#private', :as => :user_private_settings, :via => :put

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
    collection { post :search }
  end

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
      get    :clone
      get    :members
      post   :remove_members
      delete :remove_member
      post   :add_member
      post   :make_clone
      post   :build_all
    end

    collection do
      get :easy_urpmi
      get :autocomplete_user_uname
    end

    resources :products do
      # member do
      #   get :clone
      #   get :build
      # end
      resources :product_build_lists, :only => [:create, :destroy]
    end

    resources :repositories

    resources :categories, :only => [:index, :show]
  end

  resources :projects, :except => [:show] do
    resources :wiki do
      collection do
        match '_history' => 'wiki#wiki_history', :as => :history, :via => :get
        match '_access' => 'wiki#git', :as => :git, :via => :get
        match '_revert/:sha1/:sha2' => 'wiki#revert_wiki', :as => :revert, :via => [:get, :post]
        match '_compare' => 'wiki#compare_wiki', :as => :compare, :via => :post
        #match '_compare/:versions' => 'wiki#compare_wiki', :versions => /.*/, :as => :compare_versions, :via => :get
        match '_compare/:versions' => 'wiki#compare_wiki', :versions => /([a-f0-9\^]{6,40})(\.\.\.[a-f0-9\^]{6,40})/, :as => :compare_versions, :via => :get
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
        #match 'compare/*versions' => 'wiki#compare', :as => :compare_versions, :via => :get
        match 'compare/:versions' => 'wiki#compare', :versions => /([a-f0-9\^]{6,40})(\.\.\.[a-f0-9\^]{6,40})/, :as => :compare_versions, :via => :get
      end
    end
    resources :issues, :except => :edit do
      resources :comments, :only => [:edit, :create, :update, :destroy]
      resources :subscribes, :only => [:create, :destroy]
      collection do
        post :create_label
        get :search_collaborators
      end
    end
    post "labels/:label_id" => "issues#destroy_label", :as => :issues_delete_label
    post "labels/:label_id/update" => "issues#update_label", :as => :issues_update_label

    resources :build_lists, :only => [:index, :new, :create] do
      collection { post :search }
    end

    resources :collaborators, :only => [:index, :edit, :update, :add] do
      collection do
        get :edit
        post :update
        post :add
        delete :remove
      end
      member do
        post :update
      end
    end

    member do
      post :fork
      get :sections
      post :sections
      delete :remove_user
    end
  end

  resources :repositories do
    member do
      get :add_project
      delete :remove_project
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
        delete :remove
      end
      member do
        post :update
        delete :remove
      end
    end
  end

  resources :users, :groups do
    resources :platforms, :only => [:new, :create]

#    resources :repositories, :only => [:new, :create]
  end

  resources :activity_feeds, :only => [:index]

  resources :search, :only => [:index]

  match '/catalogs', :to => 'categories#platforms', :as => :catalogs

  match 'product_status', :to => 'product_build_lists#status_build'

  # Tree
  get '/projects/:project_id' => "git/trees#show", :as => :project
  get '/projects/:project_id/tree/:treeish(/*path)' => "git/trees#show", :defaults => {:treeish => :master}, :as => :tree
  # Commits
  get '/projects/:project_id/commits/:treeish(/*path)' => "git/commits#index", :defaults => {:treeish => :master}, :as => :commits, :format => false
  get '/projects/:project_id/commit/:id(.:format)' => "git/commits#show", :as => :commit
  # Commit comments
  post '/projects/:project_id/commit/:commit_id/comments(.:format)' => "comments#create", :as => :project_commit_comments
  get '/projects/:project_id/commit/:commit_id/comments/:id(.:format)' => "comments#edit", :as => :edit_project_commit_comment
  put '/projects/:project_id/commit/:commit_id/comments/:id(.:format)' => "comments#update", :as => :project_commit_comment
  delete '/projects/:project_id/commit/:commit_id/comments/:id(.:format)' => "comments#destroy"
  # Commit subscribes
  post '/projects/:project_id/commit/:commit_id/subscribe' => "commit_subscribes#create", :as => :subscribe_commit
  delete '/projects/:project_id/commit/:commit_id/unsubscribe' => "commit_subscribes#destroy", :as => :unsubscribe_commit
  # Editing files
  get '/projects/:project_id/blob/:treeish/*path/edit' => "git/blobs#edit", :defaults => {:treeish => :master}, :as => :edit_blob
  put '/projects/:project_id/blob/:treeish/*path' => "git/blobs#update", :defaults => {:treeish => :master}, :format => false
  # Blobs
  get '/projects/:project_id/blob/:treeish/*path' => "git/blobs#show", :defaults => {:treeish => :master}, :as => :blob, :format => false
  # Blame
  get '/projects/:project_id/blame/:treeish/*path' => "git/blobs#blame", :defaults => {:treeish => :master}, :as => :blame, :format => false
  # Raw
  get '/projects/:project_id/raw/:treeish/*path' => "git/blobs#raw", :defaults => {:treeish => :master}, :as => :raw, :format => false

  root :to => "activity_feeds#index"
  match '/forbidden', :to => 'platforms#forbidden', :as => 'forbidden'
end
