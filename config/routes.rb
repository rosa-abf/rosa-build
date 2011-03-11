Rosa::Application.routes.draw do
  devise_for :users

  resources :platforms do
    resources :projects do
      resource :repo, :controller => "git/repositories", :only => [:show]
    end
  end

  resources :users

  # Tree
  match 'platforms/:platform_name/projects/:project_name/git/tree/:treeish(/*path)', :controller => "git/trees", :action => :show, :platform_name => /[0-9a-zA-Z_.\-]*/, :project_name => /[0-9a-zA-Z_.\-]*/, :treeish => /[0-9a-zA-Z_.\-]*/, :defaults => { :treeish => :master }, :as => :tree

  # Commits
  match 'platforms/:platform_name//projects/:project_name/git/commits/:treeish(/*path)', :controller => "git/commits", :action => :index, :platform_name => /[0-9a-zA-Z_.\-]*/, :project_name => /[0-9a-zA-Z_.\-]*/, :treeish => /[0-9a-zA-Z_.\-]*/, :defaults => { :treeish => :master }, :as => :commits
  match 'platforms/:platform_name//projects/:project_name/git/commit/:id(.:format)', :controller => "git/commits", :action => :show, :platform_name => /[0-9a-zA-Z_.\-]*/, :project_name => /[0-9a-zA-Z_.\-]*/, :defaults => { :format => :html }, :as => :commit

  # Blobs
  match 'platforms/:platform_name/projects/:project_name/git/blob/:treeish/*path', :controller => "git/blobs", :action => :show, :platform_name => /[0-9a-zA-Z_.\-]*/, :project_name => /[0-9a-zA-Z_.\-]*/, :treeish => /[0-9a-zA-Z_.\-]*/, :defaults => { :treeish => :master }, :as => :blob
  match 'platforms/:platform_name/projects/:project_name/git/commit/blob/:commit_hash/*path', :controller => "git/blobs", :action => :show, :platform_name => /[0-9a-zA-Z_.\-]*/, :project_name => /[0-9a-zA-Z_.\-]*/, :as => :blob_commit

  # Blame
  match 'platforms/:platform_name/projects/:project_name/git/blame/:treeish/*path', :controller => "git/blobs", :action => :blame, :platform_name => /[0-9a-zA-Z_.\-]*/, :project_name => /[0-9a-zA-Z_.\-]*/, :treeish => /[0-9a-zA-Z_.\-]*/, :defaults => { :treeish => :master }, :as => :blame
  match 'platforms/:platform_name/projects/:project_name/git/commit/blame/:commit_hash/*path', :controller => "git/blobs", :action => :blame, :platform_name => /[0-9a-zA-Z_.\-]*/, :project_name => /[0-9a-zA-Z_.\-]*/, :as => :blame_commit

  # Raw
  match 'platforms/:platform_name/projects/:project_name/git/raw/:treeish/*path', :controller => "git/blobs", :action => :raw, :platform_name => /[0-9a-zA-Z_.\-]*/, :project_name => /[0-9a-zA-Z_.\-]*/, :treeish => /[0-9a-zA-Z_.\-]*/, :defaults => { :treeish => :master }, :as => :raw
  match 'platforms/:platform_name/projects/:project_name/git/commit/raw/:commit_hash/*path', :controller => "git/blobs", :action => :raw, :platform_name => /[0-9a-zA-Z_.\-]*/, :project_name => /[0-9a-zA-Z_.\-]*/, :as => :raw_commit

  root :to => "platforms#index"
end
