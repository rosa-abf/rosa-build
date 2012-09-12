# -*- encoding : utf-8 -*-
class Platforms::RepositoriesController < Platforms::BaseController
  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, :only => [:index, :show, :projects_list] if APP_CONFIG['anonymous_access']

  load_and_authorize_resource :platform
  load_and_authorize_resource :repository, :through => :platform, :shallow => true

  def index
    @repositories = @repositories.paginate(:page => params[:page])
  end

  def show
    @projects = @repository.projects.recent.paginate :page => params[:project_page], :per_page => 30
    @projects = @projects.search(params[:query]).search_order if params[:query].present?
  end

  def edit
    @members = @repository.members.order('name')
  end

  def update
    if @repository.update_attributes(
      :description => params[:repository][:description],
      :publish_without_qa => (params[:repository][:publish_without_qa] || @repository.publish_without_qa)
    )
      flash[:notice] = I18n.t("flash.repository.updated")
      redirect_to platform_repository_path(@platform, @repository)
    else
      flash[:error] = I18n.t("flash.repository.update_error")
      flash[:warning] = @repository.errors.full_messages.join('. ')
      render :action => :edit
    end
  end

  def remove_members
    Relation.remove_members(params[:user_remove], @repository)
    redirect_to edit_platform_repository_path(@platform, @repository)
  end

  def remove_member
    Relation.remove_member(params[:member_id], @repository)
    redirect_to edit_platform_repository_path(@platform, @repository)
  end

  def add_member
    if member = User.where(:id => params[:member_id]).first
      if Relation.add_member(member, @repository)
        flash[:notice] = t('flash.repository.members.successfully_added', :name => member.uname)
      else
        flash[:error] = t('flash.repository.members.error_in_adding', :name => member.uname)
      end
    end
    redirect_to edit_platform_repository_path(@platform, @repository)
  end

  def new
    @repository = Repository.new
    @platform_id = params[:platform_id]
  end

  def destroy
    @repository.destroy

    flash[:notice] = t("flash.repository.destroyed")
    redirect_to platform_repositories_path(@repository.platform)
  end

  def create
    @repository = Repository.new(params[:repository])
    @repository.platform_id = params[:platform_id]
    if @repository.save
      flash[:notice] = t('flash.repository.saved')
      redirect_to platform_repository_path(@platform, @repository)
    else
      flash[:error] = t('flash.repository.save_error')
      flash[:warning] = @repository.errors.full_messages.join('. ')
      render :action => :new
    end
  end

  def add_project
    if params[:project_id]
      @project = Project.find(params[:project_id])
      begin
        @repository.projects << @project
        flash[:notice] = t('flash.repository.project_added')
      rescue ActiveRecord::RecordInvalid
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
    @projects = @projects.paginate(
      :page => (params[:iDisplayStart].to_i/(params[:iDisplayLength].present? ? params[:iDisplayLength] : 25).to_i).to_i + 1,
      :per_page => params[:iDisplayLength].present? ? params[:iDisplayLength] : 25
    )

    @total_projects_count = @projects.count
    @projects = @projects.search(params[:sSearch]).search_order if params[:sSearch].present?
    @projects = @projects.order(order)

    render :partial => (params[:added] == "true") ? 'project' : 'proj_ajax', :layout => false
  end

  def remove_project
    @project = Project.find(params[:project_id])
    ProjectToRepository.where(:project_id => @project.id, :repository_id => @repository.id).destroy_all
    redirect_to platform_repository_path(@platform, @repository), :notice => t('flash.repository.project_removed')
  end

end
