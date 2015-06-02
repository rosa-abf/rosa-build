class Platforms::RepositoriesController < Platforms::BaseController
  include DatatableHelper
  include FileStoreHelper
  include RepositoriesHelper
  include PaginateHelper

  before_action :authenticate_user!
  skip_before_action :authenticate_user!, only: [:index, :show, :projects_list] if APP_CONFIG['anonymous_access']

  before_action :load_repository, except: [:index, :create, :new]
  before_action :set_members,     only:   [:edit, :update]
  before_action -> { @repository = @platform.repositories.find(params[:id]) if params[:id] }

  def index
    @repositories = @platform.repositories
    @repositories = Repository.custom_sort(@repositories).paginate(page: current_page)
  end

  def show
    params[:per_page] = 30
  end

  def edit
  end

  def update
    authorize @repository
    if @repository.update_attributes(repository_params)
      flash[:notice] = I18n.t("flash.repository.updated")
      redirect_to platform_repository_path(@platform, @repository)
    else
      flash[:error] = I18n.t("flash.repository.update_error")
      flash[:warning] = @repository.errors.full_messages.join('. ')
      render action: :edit
    end
  end

  def remove_members
    User.where(id: params[:members]).find_each do |user|
      @repository.remove_member(user)
    end
    redirect_to edit_platform_repository_path(@platform, @repository)
  end

  def add_member
    if member = User.find_by(id: params[:member_id])
      if @repository.add_member(member)
        flash[:notice] = t('flash.repository.members.successfully_added', name: member.uname)
      else
        flash[:error] = t('flash.repository.members.error_in_adding', name: member.uname)
      end
    end
    redirect_to edit_platform_repository_path(@platform, @repository)
  end

  def new
    authorize @repository = @platform.repositories.new
    @platform_id = params[:platform_id]
  end

  def destroy
    authorize @repository
    @repository.destroy

    flash[:notice] = t("flash.repository.destroyed")
    redirect_to platform_repositories_path(@repository.platform)
  end

  def create
    authorize @repository = @platform.repositories.build(repository_params)
    if @repository.save
      flash[:notice] = t('flash.repository.saved')
      redirect_to platform_repository_path(@platform, @repository)
    else
      flash[:error] = t('flash.repository.save_error')
      render action: :new
    end
  end

  def add_project
    authorize @repository
    if projects_list = params.try(:[], :repository).try(:[], :projects_list)
      @repository.add_projects projects_list, current_user
      redirect_to platform_repository_path(@platform, @repository), notice: t('flash.repository.projects_will_be_added')
      return
    end
    if params[:project_id].present?
      @project = Project.find(params[:project_id])
      if policy(@project).read?
        begin
          @repository.projects << @project
          flash[:notice] = t('flash.repository.project_added')
        rescue ActiveRecord::RecordInvalid
          flash[:error] = t('flash.repository.project_not_added')
        end
      else
        flash[:error] = t('flash.repository.no_access_to_read_project')
      end
      redirect_to platform_repository_path(@platform, @repository)
    else
      render :projects_list
    end
  end

  def projects_list
    render(text: @repository.projects.map(&:name).join("\n")) && return if params[:text] == 'true'

    owner_subquery = "
      INNER JOIN (
        SELECT id, 'User' AS type, uname
        FROM users
        UNION
        SELECT id, 'Group' AS type, uname
        FROM groups
      ) AS owner
      ON projects.owner_id = owner.id AND projects.owner_type = owner.type"

    if params[:added] == "true"
      @projects = @repository.projects
    else
      @projects = Project.joins(owner_subquery).addable_to_repository(@repository.id)
      @projects = @projects.opened if @repository.platform.main? && !@repository.platform.hidden?
    end
    # @projects = @projects.paginate(page: page, per_page: per_page)

    # @total_projects = @projects.count
    @projects = @projects.by_owner(params[:owner_name]).
      search(params[:project_name]).order("projects.name #{sort_dir}")

    @total_items = @projects.count
    @projects    = @projects.paginate(paginate_params)

    respond_to do |format|
      format.json {
        render partial: (params[:added] == "true") ? 'project' : 'proj_ajax', layout: false
      }
    end
  end

  def remove_project
    if projects_list = params.try(:[], :repository).try(:[], :projects_list)
      @repository.remove_projects projects_list
      redirect_to platform_repository_path(@platform, @repository), notice: t('flash.repository.projects_will_be_removed')
    end
    if params[:project_id].present?
      ProjectToRepository.where(project_id: params[:project_id], repository_id: @repository.id).destroy_all
      message = t('flash.repository.project_removed')
      respond_to do |format|
        format.html {redirect_to platform_repository_path(@platform, @repository), notice: message}
        format.json {render json: { message: message }}
      end
    end
  end

  def regenerate_metadata
    authorize @repository
    if @repository.regenerate(params[:repository].try :[], :build_for_platform_id)
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

  def repository_params
    subject_params(Repository)
  end

  # Private: before_action hook which loads Repository.
  def load_repository
    authorize @repository = @platform.repositories.find(params[:id])
  end

  def set_members
    @members = @repository.members.order('name')
  end

end
