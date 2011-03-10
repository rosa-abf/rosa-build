Rosa::Application.routes.draw do
  devise_for :users

  resources :platforms do
    resources :projects
  end

  resources :users

  # Tree
  match 'platforms/:platform_name/projects/:project_name/git/tree/:treeish(/*path)', :controller => "git/trees", :action => :show, :treeish => /[0-9a-zA-Z_.\-]*/, :defaults => { :treeish => :master }, :as => :tree

  # Commits
  match 'platforms/:platform_name//projects/:project_name/git/commits/:treeish(/*path)', :controller => "git/commits", :action => :index, :treeish => /[0-9a-zA-Z_.\-]*/, :defaults => { :treeish => :master }, :as => :commits
  match 'platforms/:platform_name//projects/:project_name/git/commit/:id(.:format)', :controller => "git/comnits", :action => :show, :defaults => { :format => :html }, :as => :commit

  # Blobs
  match 'platforms/:platform_name/projects/:project_name/git/blob/:treeish/*path', :controller => "git/blobs", :action => :show, :treeish => /[0-9a-zA-Z_.\-]*/, :defaults => { :treeish => :master }, :as => :blob
  match 'platforms/:platform_name/projects/:project_name/git/commit/blob/:commit_hash/*path', :controller => "git/blobs", :action => :show, :as => :blob_commit

  # Blame
  match 'platforms/:platform_name/projects/:project_name/git/blame/:treeish/*path', :controller => "git/blobs", :action => :blame, :treeish => /[0-9a-zA-Z_.\-]*/, :defaults => { :treeish => :master }, :as => :blame
  match 'platforms/:platform_name/projects/:project_name/git/commit/blame/:commit_hash/*path', :controller => "git/blobs", :action => :blame, :as => :blame_commit

  # Raw
  match 'platforms/:platform_name/projects/:project_name/git/raw/:treeish/*path', :controller => "git/blobs", :action => :raw, :treeish => /[0-9a-zA-Z_.\-]*/, :defaults => { :treeish => :master }, :as => :raw
  match 'platforms/:platform_name/projects/:project_name/git/commit/raw/:commit_hash/*path', :controller => "git/blobs", :action => :raw, :as => :raw_commit

  root :to => "platforms#index"
end
