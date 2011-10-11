Rosa::Application.routes.draw do
  devise_for :users, :controllers => {:omniauth_callbacks => 'users/omniauth_callbacks'} do
    get '/users/auth/:provider' => 'users/omniauth_callbacks#passthru'
  end
  resources :users

  resources :platforms do
    member do
      get 'freeze'
      get 'unfreeze'
      get 'clone'
    end

    resources :products do
      member do
        get :clone
        get :build
      end
    end

    resources :repositories do
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

        member do
          get :build
          post :process_build
        end

      end
    end
  end
  
  match 'build_lists/status_build', :to => "build_lists#status_build"
  match 'build_lists/post_build', :to => "build_lists#post_build"
  match 'build_lists/pre_build', :to => "build_lists#pre_build"
  match 'build_lists/circle_build', :to => "build_lists#circle_build"
  match 'build_lists/new_bbdt', :to => "build_lists#new_bbdt"

  match 'product_status', :to => 'products#product_status'

  # Tree
  match 'platforms/:platform_id/repositories/:repository_id/projects/:project_id/git/tree/:treeish(/*path)', :controller => "git/trees", :action => :show, :treeish => /[0-9a-zA-Z_.\-]*/, :defaults => { :treeish => :master }, :as => :tree

  # Commits
  match 'platforms/:platform_id/repositories/:repository_id/projects/:project_id/git/commits/:treeish(/*path)', :controller => "git/commits", :action => :index, :treeish => /[0-9a-zA-Z_.\-]*/, :defaults => { :treeish => :master }, :as => :commits
  match 'platforms/:platform_id/repositories/:repository_id/projects/:project_id/git/commit/:id(.:format)', :controller => "git/commits", :action => :show, :defaults => { :format => :html }, :as => :commit

  # Blobs
  match 'platforms/:platform_id/repositories/:repository_id/projects/:project_id/git/blob/:treeish/*path', :controller => "git/blobs", :action => :show, :treeish => /[0-9a-zA-Z_.\-]*/, :defaults => { :treeish => :master }, :as => :blob
  match 'platforms/:platform_id/repositories/:repository_id/projects/:project_id/git/commit/blob/:commit_hash/*path', :controller => "git/blobs", :action => :show, :platform_name => /[0-9a-zA-Z_.\-]*/, :project_name => /[0-9a-zA-Z_.\-]*/, :as => :blob_commit

  # Blame
  match 'platforms/:platform_id/repositories/:repository_id/projects/:project_id/git/blame/:treeish/*path', :controller => "git/blobs", :action => :blame, :treeish => /[0-9a-zA-Z_.\-]*/, :defaults => { :treeish => :master }, :as => :blame
  match 'platforms/:platform_id/repositories/:repository_id/projects/:project_id/git/commit/blame/:commit_hash/*path', :controller => "git/blobs", :action => :blame, :as => :blame_commit

  # Raw
  match 'platforms/:platform_id/repositories/:repository_id/projects/:project_id/git/raw/:treeish/*path', :controller => "git/blobs", :action => :raw, :treeish => /[0-9a-zA-Z_.\-]*/, :defaults => { :treeish => :master }, :as => :raw
  match 'platforms/:platform_id/repositories/:repository_id/projects/:project_id/git/commit/raw/:commit_hash/*path', :controller => "git/blobs", :action => :raw, :as => :raw_commit

  root :to => "platforms#index"
end
