Rosa::Application.routes.draw do

  # ActiveAdmin routes.
  ActiveAdmin.routes(self)

  namespace :admin do
    constraints Rosa::Constraints::AdminAccess do
      mount Resque::Server => 'resque'
    end
  end

  # Redirect sitemap1.xml.gz file on AWS S3
  match '/sitemap.xml.gz' => 'sitemap#show', via: [:get, :post, :head], as: :sitemap
  match '/robots.txt' => 'sitemap#robots', via: [:get, :post, :head], as: :robots

  resources :statistics, only: [:index]
  resource :contact, only: [:new, :create, :sended] do
    get '/' => 'contacts#new'
    get :sended
  end

  devise_scope :user do
    get '/users/auth/:provider' => 'users/omniauth_callbacks#passthru'
    get 'users/sign_up' => 'users/registrations#new',    as: :new_user_registration
    post 'users'        => 'users/registrations#create', as: :user_registration
  end

  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks',
    confirmations:      'users/confirmations'
  }, skip: [:registrations]

  namespace :api do
    namespace :v1, constraints: { format: 'json' }, defaults: { format: 'json' } do
      resources :advisories, only: [:index, :show, :create, :update]
      resources :search, only: [:index]
      resources :build_lists, only: [:index, :create, :show] do
        member {
          put :publish
          put :reject_publish
          put :rerun_tests
          put :cancel
          put :create_container
          put :publish_into_testing
        }
      end
      resources :arches, only: :index
      resources :platforms, only: %i(index show update destroy create) do
        collection {
          get :platforms_for_build
          get :allowed
        }
        member {
          get :members
          put :add_member
          delete :remove_member
          post :clone
          put :clear
        }
        resources :maintainers, only: [ :index ]
      end
      resources :repositories, only: [:show, :update, :destroy] do
        member {
          get     :projects
          get     :key_pair
          get     :packages
          put     :add_member
          delete  :remove_member
          put     :add_project
          delete  :remove_project
          put     :signatures
          put     :add_repo_lock_file
          delete  :remove_repo_lock_file
        }
      end
      resources :projects, only: [:index, :show, :update, :create, :destroy] do
        collection { get :get_id }
        member {
          post   :fork
          post   :alias
          get    :refs_list
          get    :members
          put    :add_member
          delete :remove_member
          put    :update_member
        }
        resources :build_lists, only: :index
        resources :issues, only: [:index, :create, :show, :update]
        resources :pull_requests, only: [:index, :create, :show, :update] do
          member {
            get :commits
            get :files
            put :merge
          }
        end
      end
      resources :users, only: [:show]
      get 'user' => 'users#show_current_user'
      resource :user, only: [:update] do
        member {
          get :notifiers
          put :notifiers
          get '/issues' => 'issues#user_index'
          get '/pull_requests' => 'pull_requests#user_index'
        }
      end
      resources :groups, only: [:index, :show, :update, :create, :destroy] do
        member {
          get :members
          put :add_member
          delete :remove_member
          put :update_member
          get '/issues' => 'issues#group_index'
          get '/pull_requests' => 'pull_requests#group_index'
        }
      end
      resources :products, only: [:show, :update, :create, :destroy] do
        resources :product_build_lists, only: :index
      end
      resources :product_build_lists, only: [:index, :show, :destroy, :create, :update] do
        put :cancel, on: :member
      end

      resources :jobs do
        collection do
          get :shift
          get :status
          put :feedback
          put :logs
          put :statistics
        end
      end

      #resources :ssh_keys, only: [:index, :create, :destroy]
      get 'issues' => 'issues#all_index'
      get 'pull_requests' => 'pull_requests#all_index'
    end
  end

  resources :search, only: [:index]

  get  '/forbidden'        => 'pages#forbidden',      as: 'forbidden'
  get  '/terms-of-service' => 'pages#tos',            as: 'tos'
  get  '/tour/:id'         => 'pages#tour_inside',    as: 'tour_inside', id: /projects|sources|builds/
  #match '/invite.html'     => redirect('/register_requests/new')

  get '/activity_feeds.:format' => 'home#activity', as: 'atom_activity_feeds', format: /atom/
  get '/issues' => 'home#issues'
  get '/pull_requests' => 'home#pull_requests'

  if APP_CONFIG['anonymous_access']
    authenticated do
      root to: 'home#activity'
    end
    unauthenticated do
      root to: 'home#root', as: :authenticated_root
    end
  else
    root to: 'home#activity'
  end

  resources :advisories, only: [:index, :show, :search] do
    get :search, on: :collection
  end

  scope module: 'platforms' do
    resources :platforms, constraints: {id: Platform::NAME_PATTERN} do
      member do
        put    :regenerate_metadata
        put    :clear
        get    :clone
        get    :members
        delete :remove_members
        post   :change_visibility
        post   :add_member
        post   :make_clone
        get    :advisories
      end

      resources :contents, only: %i(index) do
        collection do
          delete :remove_file
        end
      end

      resources :mass_builds, only: [:create, :new, :index, :show] do
        member do
          post   :cancel
          post   :publish
          get '/:kind' => "mass_builds#get_list", as: :get_list, kind: /failed_builds_list|missed_projects_list|projects_list|tests_failed_builds_list|success_builds_list/
        end
      end

      resources :repositories do
        member do
          get     :add_project
          put     :add_project
          get     :remove_project
          delete  :remove_project
          get     :projects_list
          delete  :remove_members
          post    :add_member
          put     :regenerate_metadata
          put     :sync_lock_file
        end
      end
      resources :key_pairs, only: [:create, :index, :destroy]
      resources :tokens, only: [:create, :index, :show, :new] do
        member do
          post :withdraw
        end
      end
      resources :products do
        resources :product_build_lists, only: [:create, :destroy, :new, :show, :update] do
          member {
            get :log
            put :cancel
          }
        end
        collection { get :autocomplete_project }
      end
      resources :maintainers, only: [:index]
    end

    resources :product_build_lists, only: [:index, :show, :update]
  end

  resources :autocompletes, only: [] do
    collection do
      get :autocomplete_user_uname
      get :autocomplete_extra_build_list
      get :autocomplete_extra_mass_build
      get :autocomplete_extra_repositories
      get :autocomplete_user_or_group
    end
  end

  scope module: 'users' do
    get '/settings/ssh_keys'            => 'ssh_keys#index', as: :ssh_keys
    post '/settings/ssh_keys'           => 'ssh_keys#create'
    delete '/settings/ssh_keys/:id' => 'ssh_keys#destroy', as: :ssh_key

    resources :settings, only: [] do
      collection do
        get :profile
        patch :profile
        get :private
        patch :private
        get :notifiers
        patch :notifiers
        get :builds_settings
        patch :builds_settings
        put :reset_auth_token
      end
    end
    #resources :register_requests, only: [:new, :create], format: /ru|en/ #view support only two languages

    get '/allowed'  => 'users#allowed'
    get '/check'    => 'users#check'
    get '/discover' => 'users#discover'
  end

  scope module: 'groups' do
    get '/groups/new' => 'profile#new' # need to force next route exclude id: 'new'
    get '/groups/:id' => redirect("/%{id}"),        as: :profile_group # override default group show route
    resources :groups, controller: 'profile' do
      delete :remove_user, on: :member
      resources :members, only: [:index] do
        collection do
          post   :add
          put    :update
          delete :remove
        end
      end
    end
  end

  scope module: 'projects' do
    resources :build_lists, only: [:index, :show] do
      member do
        put :cancel
        put :create_container
        put :rerun_tests
        get :log
        patch :publish
        put :reject_publish
        put :publish_into_testing
        put :update_type
        get :dependent_projects
        post :dependent_projects
      end
    end

    resources :projects, only: [:index, :new, :create] do
      collection do
        post  :run_mass_import
        get   :mass_import
      end
    end
    scope '*name_with_owner', constraints: { name_with_owner: Project::OWNER_AND_NAME_REGEXP } do # project
      scope as: 'project' do
        resources :wiki do
          collection do
            match '_history' => 'wiki#wiki_history', as: :history, via: :get
            match '_access' => 'wiki#git', as: :git, via: :get
            match '_revert/:sha1/:sha2' => 'wiki#revert_wiki', as: :revert, via: [:get, :post]
            match '_compare' => 'wiki#compare_wiki', as: :compare, via: :post
            #match '_compare/:versions' => 'wiki#compare_wiki', versions: /.*/, as: :compare_versions, via: :get
            match '_compare/:versions' => 'wiki#compare_wiki', versions: /([a-f0-9\^]{6,40})(\.\.\.[a-f0-9\^]{6,40})/, as: :compare_versions, via: :get
            post :preview
            get :search
            get :pages
          end
          member do
            get :history
            get :edit
            match 'revert/:sha1/:sha2' => 'wiki#revert', as: :revert_page, via: [:get, :post]
            match ':ref' => 'wiki#show', as: :versioned, via: :get

            post :compare
            #match 'compare/*versions' => 'wiki#compare', as: :compare_versions, via: :get
            match 'compare/:versions' => 'wiki#compare', versions: /([a-f0-9\^]{6,40})(\.\.\.[a-f0-9\^]{6,40})/, as: :compare_versions, via: :get
          end
        end
        resources :issues, except: [:destroy, :edit] do
          resources :comments, only: [:edit, :create, :update, :destroy]
          post '/subscribe'     => "subscribes#create", as: :subscribe
          delete '/unsubscribe' => "subscribes#destroy", as: :unsubscribe
          collection do
            post :create_label
            get :search_collaborators
          end
        end

        get  'pull_requests'           => 'issues#pull_requests', as: :pull_requests
        get  'labels'                  => 'issues#labels',        as: :labels
        post 'labels/:label_id'        => 'issues#destroy_label', as: :issues_delete_label
        post 'labels/:label_id/update' => 'issues#update_label',  as: :issues_update_label

        resources :build_lists, only: [:index, :new, :create] do
          get :list, on: :collection
        end
        resources :collaborators do
          get :find, on: :collection
        end
        resources :hooks, except: :show
        resources :pull_requests, except: [:index, :destroy] do
          get :autocomplete_to_project, on: :collection
          put :merge, on: :member
        end
        post '/preview' => 'projects#preview', as: 'md_preview'
        post 'refs_list' => 'projects#refs_list', as: 'refs_list'
        put 'schedule' => 'projects#schedule'
      end

      # Resource
      get '/autocomplete_maintainers' => 'projects#autocomplete_maintainers', as: :autocomplete_maintainers
      get '/modify' => 'projects#edit', as: :edit_project
      patch '/' => 'projects#update'
      delete '/' => 'projects#destroy'
      # Member
      post '/fork'  => 'projects#fork',  as: :fork_project
      post '/alias' => 'projects#alias', as: :alias_project
      get '/possible_forks' => 'projects#possible_forks', as: :possible_forks_project
      get '/sections' => 'projects#sections', as: :sections_project
      patch '/sections' => 'projects#sections'
      delete '/remove_user' => 'projects#remove_user', as: :remove_user_project
      # constraints treeish: /[\w\-\.]+(\/[\w\-\.]+)?/ do
      constraints treeish: /.+/ do
        constraints Rosa::Constraints::Treeish do
          # Tree
          get '/' => "git/trees#show", as: :project
          get '/tree/*treeish' => "git/trees#show", as: :tree, format: false
          # Tags
          get '/tags' => "git/trees#tags", as: :tags
          # Branches
          get '/branches' => "git/trees#branches", as: :branches
          get '/branches/:treeish' => "git/trees#branches", as: :branch
          delete '/branches/:treeish' => "git/trees#destroy", as: :destroy_branch
          put '/branches/:treeish' => "git/trees#restore_branch", as: :restore_branch
          post '/branches' => "git/trees#create", as: :create_branch
          # Commits
          get '/commits/:treeish(/*path)' => "git/commits#index", as: :commits, format: false
          get '/commit/:id(.:format)' => "git/commits#show", as: :commit
          # Commit comments
          post '/commit/:commit_id/comments(.:format)' => "comments#create", as: :project_commit_comments
          get '/commit/:commit_id/comments/:id(.:format)' => "comments#edit", as: :edit_project_commit_comment
          patch '/commit/:commit_id/comments/:id(.:format)' => "comments#update", as: :project_commit_comment
          delete '/commit/:commit_id/comments/:id(.:format)' => "comments#destroy"
          get '/commit/:commit_id/add_line_comments(.:format)' => "comments#new_line", as: :new_line_commit_comment
          # Commit subscribes
          post '/commit/:commit_id/subscribe' => "commit_subscribes#create", as: :subscribe_commit
          delete '/commit/:commit_id/unsubscribe' => "commit_subscribes#destroy", as: :unsubscribe_commit
          # Editing files
          get '/edit/:treeish/*path' => "git/blobs#edit", as: :edit_blob, format: false
          put '/edit/:treeish/*path' => "git/blobs#update", format: false
          # Blobs
          get '/blob/:treeish/*path' => "git/blobs#show", as: :blob, format: false
          # Blame
          get '/blame/:treeish/*path' => "git/blobs#blame", as: :blame, format: false
          # Raw
          get '/raw/:treeish/*path' => "git/blobs#raw", as: :raw, format: false
          # Archive
          get '/archive/:treeish.:format' => "git/trees#archive", as: :archive, format: /zip|tar\.gz/
          # Git diff
          get '/diff/:diff' => "git/commits#diff", as: :diff, format: false, diff: /.*/
        end
      end
    end
  end

  scope ':uname' do # project owner profile
    constraints Rosa::Constraints::Owner.new(User) do
      get '/' => 'users/profile#show', as: :user
    end
    constraints Rosa::Constraints::Owner.new(Group, true) do
      get '/' => 'groups/profile#show'
    end
  end

  # As of Rails 3.0.1, using rescue_from in your ApplicationController to
  # recover from a routing error is broken!
  # see: https://rails.lighthouseapp.com/projects/8994/tickets/4444-can-no-longer-rescue_from-actioncontrollerroutingerror
  get '*a', to: 'application#render_404'
end
