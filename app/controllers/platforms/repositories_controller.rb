# -*- encoding : utf-8 -*-
class Platforms::RepositoriesController < Platforms::BaseController
  include FileStoreHelper

  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, :only => [:index, :show, :projects_list] if APP_CONFIG['anonymous_access']

  load_and_authorize_resource :platform
  load_and_authorize_resource :repository, :through => :platform, :shallow => true
  before_filter :set_members, :only => [:edit, :update]

  def index
    @repositories = Repository.custom_sort(@repositories).paginate(:page => params[:page])
  end

  def show
    @projects = @repository.projects.recent.search(params[:query])
                           .paginate(:page => params[:project_page], :per_page => 30)
  end

  def edit
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
    user_ids = params[:user_remove] ?
      params[:user_remove].map{ |k, v| k if v.first == '1' }.compact : []
    User.where(:id => user_ids).each{ |user| @repository.remove_member(user) }
    redirect_to edit_platform_repository_path(@platform, @repository)
  end

  def remove_member
    User.where(:id => params[:member_id]).each{ |user| @repository.remove_member(user) }
    redirect_to edit_platform_repository_path(@platform, @repository)
  end

  def add_member
    if member = User.where(:id => params[:member_id]).first
      if @repository.add_member(member)
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
    @repository = @platform.repositories.build(params[:repository])
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
    if projects_list = params.try(:[], :repository).try(:[], :projects_list)
      @repository.add_projects projects_list, current_user
      redirect_to platform_repository_path(@platform, @repository), :notice => t('flash.repository.projects_will_be_added')
      return
    end
    if params[:project_id]
      @project = Project.find(params[:project_id])
      if can?(:read, @project)
        begin
          @repository.projects << @project
          flash[:notice] = t('flash.repository.project_added')
        rescue ActiveRecord::RecordInvalid
          flash[:error] = t('flash.repository.project_not_added')
        end
      else
        flash[:error] = t('flash.repository.project_not_added')
      end
      redirect_to platform_repository_path(@platform, @repository)
    else
      render :projects_list
    end
  end

  def projects_list
    render(:text => @repository.projects.map(&:name).join("\n")) && return if params[:text] == 'true'

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
      @projects = @projects.opened if @repository.platform.main? && !@repository.platform.hidden?
    end
    @projects = @projects.paginate(
      :page => (params[:iDisplayStart].to_i/(params[:iDisplayLength].present? ? params[:iDisplayLength] : 25).to_i).to_i + 1,
      :per_page => params[:iDisplayLength].present? ? params[:iDisplayLength] : 25
    )

    @total_projects = @projects.count
    @projects = @projects.search(params[:sSearch]).order(order)

    respond_to do |format|
      format.json {
        render :partial => (params[:added] == "true") ? 'project' : 'proj_ajax', :layout => false
      }
    end
  end

  def remove_project
    if projects_list = params.try(:[], :repository).try(:[], :projects_list)
      @repository.remove_projects projects_list
      redirect_to platform_repository_path(@platform, @repository), :notice => t('flash.repository.projects_will_be_removed')
    end
    if params[:project_id]
      ProjectToRepository.where(:project_id => params[:project_id], :repository_id => @repository.id).destroy_all
      redirect_to platform_repository_path(@platform, @repository), :notice => t('flash.repository.project_removed')
    end
  end

  def regenerate_metadata
    if @repository.regenerate(params[:build_for_platform_id])
      flash[:notice] = t('flash.repository.regenerate_in_queue')
    else
      flash[:error] = t('flash.repository.regenerate_already_in_queue')
    end
    redirect_to platform_repository_path(@platform, @repository)
  end

  def sync_lock_file
    if params[:remove]
      @repository.remove_sync_lock_file
      flash[:notice] = t('flash.repository.sync_lock_file_removed')
    else
      flash[:notice] = t('flash.repository.sync_lock_file_added')
      @repository.add_sync_lock_file
    end
    redirect_to edit_platform_repository_path(@platform, @repository)
  end

  protected

  def set_members
    @members = @repository.members.order('name')
  end

end
