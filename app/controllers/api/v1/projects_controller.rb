class Api::V1::ProjectsController < Api::V1::BaseController

  before_action :authenticate_user!
  skip_before_action :authenticate_user!, only: [:get_id, :show, :refs_list] if APP_CONFIG['anonymous_access']

  load_and_authorize_resource :project

  def index
    @projects = Project.accessible_by(current_ability, :membered)
                       .paginate(paginate_params)
    respond_to :json
  end

  def get_id
    if @project = Project.find_by_owner_and_name(params[:owner], params[:name])
      authorize @project, :show?
    else
      raise ActiveRecord::RecordNotFound
    end
    respond_to :json
  end

  def show
    authorize @project, :show?
    respond_to :json
  end

  def refs_list
    authorize @project, :show?
    @refs = @project.repo.branches + @project.repo.tags.select{ |t| t.commit }
    respond_to :json
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
    authorize @project.owner, :write? if @project.owner != current_user
    create_subject @project
  end

  def members
    @members = @project.collaborators.order('uname').paginate(paginate_params)
    respond_to :json
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

  def fork(is_alias = false)
    owner = (Group.find params[:group_id] if params[:group_id].present?) || current_user
    authorize owner, :write? if owner.class == Group
    if forked = @project.fork(owner, new_name: params[:fork_name], is_alias: is_alias) and forked.valid?
      render_json_response forked, 'Project has been forked successfully'
    else
      render_validation_error forked, 'Project has not been forked'
    end
  end

  def alias
    fork(true)
  end
end
