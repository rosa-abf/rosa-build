class Projects::CollaboratorsController < Projects::BaseController
  respond_to :html, :json

  before_action :authenticate_user!
  before_action :authorize_collaborators

  before_action :find_users
  before_action :find_groups

  def index
    @collaborators = Collaborator.find_by_project(@project)
    respond_with @collaborators
  end

  def find
    users = User.not_member_of(@project)
    groups = Group.not_member_of(@project)
    if params[:term].present?
      users = users.search(params[:term]).first(5)
      groups = groups.search(params[:term]).first(5)
    end
    @collaborators = (users | groups).map{|act| Collaborator.new(actor: act, project: @project)}
    respond_with @collaborators
  end

  def create
    @collaborator = Collaborator.new(collaborator_params)
    @collaborator.project = @project
    respond_to do |format|
      if @collaborator.save
        format.json { render partial: 'collaborator', locals: {collaborator: @collaborator, success: true} }
      else
        format.json { render json: {message:t('flash.collaborators.error_in_adding')}, status: 422 }
      end
    end
  end

  def update
    cb = Collaborator.find(params[:id])
    respond_to do |format|
      if cb.update_attributes(params[:collaborator])
        format.json { render json: {message:t('flash.collaborators.successfully_updated', uname: cb.actor.uname)} }
      else
        format.json { render json: {message:t('flash.collaborators.error_in_updating')}, status: 422 }
      end
    end
  end

  def destroy
    cb = Collaborator.find(params[:id])
    respond_to do |format|
      if cb.present? && cb.destroy
        format.json { render json: {message:t('flash.collaborators.successfully_removed', uname: cb.actor.uname)} }
      else
        format.json {
          render json: {message:t('flash.collaborators.error_in_removing', uname: cb.try(:actor).try(:uname))},
                 status: 422
        }
      end
    end
  end

  protected

  def collaborator_params
    subject_params(Collaborator)
  end

  def find_users
    @users = @project.collaborators.order('uname')#User.all
    @users = @users.without(@project.owner_id) if @project.owner_type == 'User'
  end

  def find_groups
    @groups = @project.groups.order('uname')#Group.all
    @groups = @groups.without(@project.owner_id) if @project.owner_type == 'Group'
  end

  def authorize_collaborators
    authorize @project, :update?
  end
end
