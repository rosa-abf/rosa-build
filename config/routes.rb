# -*- encoding : utf-8 -*-
Rosa::Application.routes.draw do
  devise_scope :user do
    get '/users/auth/:provider' => 'users/omniauth_callbacks#passthru'
    get '/user' => 'users#profile', :as => :edit_profile
    put '/user' => 'users#update', :as => :update_profile
    get '/users' => 'admin/users#index', :as => :users
    get '/users/new' => 'admin/users#new', :as => :new_user
    get '/users/list' => 'admin/users#list', :as => :users_list
    post '/users/create' => 'admin/users#create', :as => :create_user
    constraints :id => /\d+/ do
      get '/users/:id/edit' => 'admin/users#profile', :as => :edit_user
      put '/users/:id/edit' => 'admin/users#update', :as => :update_user
      delete '/users/:id/delete' => 'admin/users#destroy', :as => :delete_user
    end
  end
  devise_for :users, :controllers => {:omniauth_callbacks => 'users/omniauth_callbacks'}
  resources :users, :only => [:show, :profile, :update] do
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
  get 'users/:id/settings/private' => 'users#private', :as => :user_private_settings
  put 'users/:id/settings/private' => 'users#private'

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
      get :autocomplete_user_uname
    end
    resources :repositories do
      member do
        get :add_project
        delete :remove_project
        get :projects_list
      end
    end
    resources :products do
      resources :product_build_lists, :only => [:create, :destroy]
    end
  end
  match '/private/:platform_name/*file_path' => 'privates#show'

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

  get '/projects/:id/archive/:format/tree/:treeish' => "projects#archive", :defaults => {:treeish => :master}, :as => :archive, :format => /zip|tar/

  # Core callbacks
  match 'build_lists/publish_build', :to => "build_lists#publish_build"
  match 'build_lists/status_build', :to => "build_lists#status_build"
  match 'build_lists/post_build', :to => "build_lists#post_build"
  match 'build_lists/pre_build', :to => "build_lists#pre_build"
  match 'build_lists/circle_build', :to => "build_lists#circle_build"
  match 'build_lists/new_bbdt', :to => "build_lists#new_bbdt"
  match 'product_status', :to => 'product_build_lists#status_build'

  resources :build_lists, :only => [:index, :show] do
    member do
      put :cancel
      put :publish
    end
    collection { post :search }
  end
  resources :product_build_lists, :only => [:index]

  resources :search, :only => [:index]

  resources :event_logs, :only => :index

  match '/forbidden', :to => 'pages#forbidden', :as => 'forbidden'
  match '/terms-of-service', :to => 'pages#tos', :as => 'tos'

  match '/.atom', :to => "activity_feeds#index", :format => :atom, :as => :atom_feed

  if APP_CONFIG['anonymous_access']
    authenticated do
      root :to => "activity_feeds#index"
    end
    root :to => 'pages#root'
  else
    root :to => "activity_feeds#index"
  end
end
