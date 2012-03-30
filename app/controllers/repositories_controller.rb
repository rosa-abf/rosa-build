# -*- encoding : utf-8 -*-
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
      @repositories = Platform.find(params[:platform_id]).repositories.paginate(:page => params[:page])
    else
      @repositories = Repository.paginate(:page => params[:page])
    end
  end

  def show
    @projects = @repository.projects.recent.paginate :page => params[:project_page], :per_page => 30
    @projects = @projects.search(params[:query]).search_order if params[:query].present?
  end

  def new
    @repository = Repository.new
    @platform_id = params[:platform_id]
  end

  def destroy
    @repository.destroy
    platform_id = @repository.platform_id

    flash[:notice] = t("flash.repository.destroyed")
    redirect_to platform_repositories_path(platform_id)
  end

  def create
    @repository = Repository.new(params[:repository])
    @repository.platform_id = params[:platform_id]
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
      unless @repository.projects.find_by_name(@project.name)
        @repository.projects << @project
        flash[:notice] = t('flash.repository.project_added')
      else
        flash[:error] = t('flash.repository.project_not_added')
      end
      redirect_to platform_repository_path(@platform, @repository)
    else
      render :projects_list
    end
  end

  def projects_list

    owner_subquery = "
      INNER JOIN (
        SELECT id, 'User' AS type, uname
        FROM users
        UNION
        SELECT id, 'Group' AS type, uname
        FROM groups
      ) AS owner
      ON projects.owner_id = owner.id AND projects.owner_type = owner.type"
    colName = ['projects.name']
    sort_col = params[:iSortCol_0] || 0
    sort_dir = params[:sSortDir_0]=="asc" ? 'asc' : 'desc'
    order = "#{colName[sort_col.to_i]} #{sort_dir}"

    if params[:added] == "true"
      @projects = @repository.projects
    else
      @projects = Project.joins(owner_subquery).addable_to_repository(@repository.id)
      @projects = @projects.by_visibilities('open') if @repository.platform.platform_type == 'main'
    end
    @projects = @projects.paginate(:page => (params[:iDisplayStart].to_i/params[:iDisplayLength].to_i).to_i + 1, :per_page => params[:iDisplayLength])

    @total_projects = @projects.count
    @projects = @projects.search(params[:sSearch]).search_order if params[:sSearch].present?
    @total_project = @projects.count
    @projects = @projects.order(order)#.includes(:owner) #WTF????

    render :partial => (params[:added] == "true") ? 'project' : 'proj_ajax', :layout => false
  end

  def remove_project
    @project = Project.find(params[:project_id])
    ProjectToRepository.where(:project_id => @project.id, :repository_id => @repository.id).destroy_all
    redirect_to platform_repository_path(@platform, @repository), :notice => t('flash.repository.project_removed')
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
