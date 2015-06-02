class Projects::ProjectsController < Projects::BaseController
  include DatatableHelper
  include ProjectsHelper

  before_action :authenticate_user!
  before_action :who_owns, only: [:new, :create, :mass_import, :run_mass_import]

  def index
    authorize :project
    @projects = ProjectPolicy::Scope.new(current_user, Project).membered.search(params[:search])
    respond_to do |format|
      format.html {
        @groups = current_user.groups
        @owners = User.where(id: @projects.where(owner_type: 'User').uniq.pluck(:owner_id))
      }
      format.json {
        groups = params[:groups] || []
        owners = params[:users] || []
        @projects = @projects.by_owners(groups, owners) if groups.present? || owners.present?
        @projects_count = @projects.count
        @projects = @projects.recent.paginate(page: current_page, per_page: Project.per_page)
      }
    end
  end

  def new
    authorize :project
    @project = Project.new
  end

  def mass_import
    authorize :project
    @project = Project.new(mass_import: true)
  end

  def run_mass_import
    @project = Project.new project_params
    @project.owner = choose_owner
    authorize @project
    @project.valid?
    @project.errors.messages.slice! :url
    if @project.errors.messages.blank? # We need only url validation
      @project.init_mass_import
      flash[:notice] = t('flash.project.mass_import_added_to_queue')
      redirect_to projects_path
    else
      render :mass_import
    end
  end

  def edit
    authorize @project
    @project_aliases = Project.project_aliases(@project).paginate(page: current_page)
  end

  def create
    @project = Project.new project_params
    @project.owner = choose_owner
    authorize @project

    if @project.save
      flash[:notice] = t('flash.project.saved')
      redirect_to @project
    else
      flash[:error] = t('flash.project.save_error')
      flash[:warning] = @project.errors.full_messages.join('. ')
      render action: :new
    end
  end

  def update
    authorize @project
    params[:project].delete(:maintainer_id) if params[:project][:maintainer_id].blank?
    respond_to do |format|
      format.html do
        if @project.update_attributes(project_params)
          flash[:notice] = t('flash.project.saved')
          redirect_to @project
        else
          flash[:error] = t('flash.project.save_error')
          flash[:warning] = @project.errors.full_messages.join('. ')
          render action: :edit
        end
      end
      format.json do
        if @project.update_attributes(project_params)
          render json: { notice: I18n.t('flash.project.saved') }
        else
          render json: { error: I18n.t('flash.project.save_error') }, status: 422
        end
      end
    end
  end

  def schedule
    authorize @project
    p_to_r = @project.project_to_repositories.find_by(repository_id: params[:repository_id])
    unless p_to_r.repository.publish_without_qa
      authorize p_to_r.repository.platform, :local_admin_manage?
    end
    p_to_r.user_id      = current_user.id
    p_to_r.enabled      = params[:enabled].present?
    p_to_r.auto_publish = params[:auto_publish].present?
    p_to_r.save
    if p_to_r.save
      render json: { notice: I18n.t('flash.project.saved') }.to_json
    else
      render json: { error: I18n.t('flash.project.save_error') }.to_json, status: 422
    end
  end

  def destroy
    authorize @project
    @project.destroy
    flash[:notice] = t("flash.project.destroyed")
    redirect_to @project.owner
  end

  def fork(is_alias = false)
    owner = (Group.find params[:group] if params[:group].present?) || current_user
    authorize owner, :write?
    if forked = @project.fork(owner, new_name: params[:fork_name], is_alias: is_alias) and forked.valid?
      redirect_to forked, notice: t("flash.project.forked")
    else
      flash[:warning] = t("flash.project.fork_error")
      flash[:error] = forked.errors.full_messages.join("\n")
      redirect_to @project
    end
  end

  def alias
    authorize @project
    fork(true)
  end

  def possible_forks
    authorize @project
    render partial: 'projects/git/base/forks', layout: false,
      locals: { owner: current_user, name: (params[:name].presence || @project.name) }
  end

  def sections
    authorize @project, :update?
    if request.patch?
      if @project.update_attributes(project_params)
        flash[:notice] = t('flash.project.saved')
        redirect_to sections_project_path(@project)
      else
        @project.save
        flash[:error] = t('flash.project.save_error')
      end
    end
  end

  def remove_user
    authorize @project
    @project.relations.by_actor(current_user).destroy_all
    respond_to do |format|
      format.html do
        flash[:notice] = t("flash.project.user_removed")
        redirect_to projects_path
      end
      format.json { render nothing: true }
    end
  end

  def autocomplete_maintainers
    authorize @project
    term, limit = params[:query], params[:limit] || 10
    items = User.member_of_project(@project)
                .where("users.name ILIKE ? OR users.uname ILIKE ?", "%#{term}%", "%#{term}%")
                .limit(limit).map { |u| {name: u.fullname, id: u.id} }
    render json: items
  end

  def preview
    authorize @project
    respond_to do |format|
      format.json {}
      format.html {render inline: view_context.markdown(params[:text]), layout: false}
    end
  end

  def refs_list
    authorize @project
    refs = @project.repo.branches_and_tags.map(&:name)
    @selected   = params[:selected] if refs.include?(params[:selected])
    @selected ||= @project.resolve_default_branch
    render layout: false
  end

  protected

  def project_params
    subject_params(Project)
  end

  def who_owns
    @who_owns = (@project.try(:owner_type) == 'User' ? :me : :group)
  end

  def choose_owner
    if params[:who_owns] == 'group'
      Group.find(params[:owner_id])
    else
      current_user
    end
  end
end
