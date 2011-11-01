class RepositoriesController < ApplicationController
  before_filter :authenticate_user!
  #before_filter :find_platform, :except => [:index, :new, :create]
  before_filter :find_repository, :only => [:show, :destroy, :add_project, :remove_project]
  before_filter :get_paths, :only => [:show, :new, :create, :add_project, :remove_project]
  before_filter :find_platforms, :only => [:new, :create]
  before_filter :check_global_access, :only => [:index, :new, :create]

  def index
    @repositories = Repository.paginate(:page => params[:repository_page])
  end

  def show
    can_perform? @repository if @repository
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
    can_perform? @repository if @repository
    @repository.destroy
    platform_id = @repository.platform_id

    flash[:notice] = t("flash.repository.destroyed")
    redirect_to platform_path(platform_id)
  end

  def create
    @repository = Repository.new(params[:repository])
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
    can_perform? @repository if @repository
    if params[:project_id]
      @project = Project.find(params[:project_id])
      params[:project_id] = nil
      unless @repository.projects.include? @project
        @repository.projects << @project
#        if @repository.save
          flash[:notice] = t('flash.repository.project_added')
          redirect_to platform_repository_path(@repository.platform, @repository)
#        else
#          flash[:error] = t('flash.repository.project_not_added')
#          redirect_to url_for(:action => :add_project)
#        end
      else
        flash[:error] = t('flash.repository.project_not_added')
        redirect_to url_for(:action => :add_project)
      end
    else
      @projects = Project.scoped
      @projects = @projects.addable_to_repository(@repository.id)
      @projects = @projects.by_visibilities(['open']) if @repository.platform.platform_type == 'main'
      @projects.paginate(:page => params[:project_page])
      #@projects = Project.addable_to_repository(@repository.id).paginate(:page => params[:project_page])
      render 'projects_list'
    end
  end

  def remove_project
    can_perform? @repository if @repository
    if params[:project_id]
      @project = Project.find(params[:project_id])
      params[:project_id] = nil
      if @repository.projects.include? @project
        @repository.projects.delete @project
#        if @repository.save
          flash[:notice] = t('flash.repository.project_removed')
          redirect_to platform_repository_path(@repository.platform, @repository)
#        else
#          flash[:error] = t('flash.repository.project_not_removed')
#          redirect_to url_for(:action => :remove_project)
#        end
      else
        redirect_to url_for(:action => :remove_project)
      end
    else
      redirect_to platform_repository_path(@repository.platform, @repository)
    end
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
end
