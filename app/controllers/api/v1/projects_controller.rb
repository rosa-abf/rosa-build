class Api::V1::ProjectsController < Api::V1::BaseController

  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, only: [:get_id, :show, :refs_list] if APP_CONFIG['anonymous_access']

  load_and_authorize_resource :project

  def index
    @projects = Project.accessible_by(current_ability, :membered)
                       .paginate(paginate_params)
    respond_to do |format|
      format.json
    end
  end

  def get_id
    if @project = Project.find_by_owner_and_name(params[:owner], params[:name])
      authorize! :show, @project
    else
      raise ActiveRecord::RecordNotFound
    end
    respond_to do |format|
      format.json
    end
  end

  def show
    respond_to do |format|
      format.json
    end
  end

  def refs_list
    @refs = @project.repo.branches + @project.repo.tags.select{ |t| t.commit }
    respond_to do |format|
      format.json
    end
  end

  def update
    update_subject @project
  end

  def destroy
    destroy_subject @project
  end

  def create
    p_params = params[:project] || {}
    owner_type = p_params[:owner_type]
    if owner_type.present? && %w(User Group).include?(owner_type)
      @project.owner = owner_type.constantize.
        where(id: p_params[:owner_id]).first
    else
      @project.owner = nil
    end
    authorize! :write, @project.owner if @project.owner != current_user
    create_subject @project
  end

  def members
    @members = @project.collaborators.order('uname').paginate(paginate_params)
    respond_to do |format|
      format.json
    end
  end

  def add_member
    add_member_to_subject @project, params[:role]
  end

  def remove_member
    remove_member_from_subject @project
  end

  def update_member
    update_member_in_subject @project
  end

  def fork
    owner = (Group.find params[:group_id] if params[:group_id].present?) || current_user
    authorize! :write, owner if owner.class == Group
    if forked = @project.fork(owner, params[:fork_name]) and forked.valid?
      render_json_response forked, 'Project has been forked successfully'
    else
      render_validation_error forked, 'Project has not been forked'
    end
  end

end
