class RepositoriesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_repository, :except => [:index, :new, :create]
  before_filter :find_platform, :only => [:show, :destroy, :add_project, :remove_project]
  before_filter :get_paths, :only => [:show, :new, :create, :add_project, :remove_project]
  before_filter :find_platforms, :only => [:new, :create]
  before_filter :build_repository_stub, :only => [:new, :create]

  load_and_authorize_resource :platform
  load_and_authorize_resource :repository, :through => :platform, :shallow => true

  def index
    if params[:platform_id]
      @repositories = Platform.find(params[:platform_id]).repositories.paginate(:page => params[:repository_page])
    else
      @repositories = Repository.paginate(:page => params[:repository_page])
    end
  end

  def show
    if params[:query]
      @projects = @repository.projects.recent.by_name(params[:query]).paginate :page => params[:project_page], :per_page => 30
    else
      @projects = @repository.projects.recent.paginate :page => params[:project_page], :per_page => 30
    end
  end

  def new
    @repository = Repository.new
    @platform_id = params[:platform_id]
  end

  def destroy
    @repository.destroy
    platform_id = @repository.platform_id

    flash[:notice] = t("flash.repository.destroyed")
    redirect_to platform_path(platform_id)
  end

  def create
    @repository = Repository.new(params[:repository])
    @repository.platform_id = params[:platform_id]
    @repository.owner = get_owner
    if @repository.save
      flash[:notice] = t('flash.repository.saved')
      redirect_to @repositories_path
    else
      flash[:error] = t('flash.repository.save_error')
      render :action => :new
    end
  end

  def add_project
    if params[:project_id]
      @project = Project.find(params[:project_id])
      # params[:project_id] = nil
      unless @repository.projects.find_by_name(@project.name)
        @repository.projects << @project
        flash[:notice] = t('flash.repository.project_added')
      else
        flash[:error] = t('flash.repository.project_not_added')
      end
      redirect_to repository_path(@repository)
    else
      if @repository.platform.platform_type == 'main'
        @projects = Project.addable_to_repository(@repository.id).by_visibilities(['open']).paginate(:page => params[:project_page])
      else
        @projects = Project.addable_to_repository(@repository.id).paginate(:page => params[:project_page])
      end
      render 'projects_list'
    end
  end

  def remove_project
    @project = Project.find(params[:project_id])
    ProjectToRepository.where(:project_id => @project.id, :repository_id => @repository.id).destroy_all
    redirect_to repository_path(@repository), :notice => t('flash.repository.project_removed')
  end

  protected

    def get_paths
      if params[:user_id]
        @user = User.find params[:user_id]
        @repositories_path = user_repositories_path @user
        @new_repository_path = new_user_repository_path @user
      elsif params[:group_id]
        @group = Group.find params[:group_id]
        @repositories_path = group_repositories_path @group
        @new_repository_path = new_group_repository_path @group
      elsif params[:platform_id]
        @platform = Platform.find params[:platform_id]
        @repositories_path = platform_repositories_path @platform
        @new_repository_path = new_platform_repository_path @platform
      else
        @repositories_path = repositories_path
        @new_repository_path = new_repository_path
      end
    end

    def find_platform
      @platform = @repository.platform
    end

    def find_platforms
      @platforms = Platform.all
    end

    def find_repository
      @repository = Repository.find(params[:id])
    end

    def build_repository_stub
      @repository = Repository.build_stub(Platform.find(params[:platform_id]))
    end
end
