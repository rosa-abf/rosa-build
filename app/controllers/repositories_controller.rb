class RepositoriesController < ApplicationController
  before_filter :authenticate_user!
#  before_filter :find_platform, :except => [:index, :new, :create]
  before_filter :find_repository, :only => [:show, :destroy]
  before_filter :get_paths, :only => [:new, :create]
  before_filter :find_platforms, :only => [:new, :create]

  def index
    @repositories = Repository.paginate(:page => params[:repository_page])
  end

  def show
    if params[:query]
      @projects = @repository.projects.recent.by_name(params[:query]).paginate :page => params[:page], :per_page => 30
    else
      @projects = @repository.projects.recent.paginate :page => params[:page], :per_page => 30
    end
  end

  def new
    @repository = Repository.new
  end

  def destroy
    @repository.destroy

    flash[:notice] = t("flash.repository.destroyed")
    redirect_to platform_path(@platform)
  end

  def create
    @repository = Repository.new(params[:repository])
    @repository.owner = get_acter
    if @repository.save
      flash[:notice] = t('flash.repository.saved')
      redirect_to @repositories_path
    else
      flash[:error] = t('flash.repository.save_error')
      render :action => :new
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

    def find_platforms
      @platforms = Platform.all
    end

    def find_repository
      @repository = Repository.find(params[:id])
    end
end
