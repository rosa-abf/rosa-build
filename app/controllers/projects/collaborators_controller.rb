class Projects::CollaboratorsController < Projects::BaseController
  respond_to :html, :json

  before_action :authenticate_user!
  load_resource :project
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
    @collaborator = Collaborator.new(params[:collaborator])
    @collaborator.project = @project
    respond_to do |format|
      if @collaborator.save
        format.json { render partial: 'collaborator', locals: {collaborator: @collaborator} }
      else
        format.json { render text: 'error', status: 422 }
      end
    end
  end

  def update
    @c = Collaborator.find(params[:id])
    if @c.update_attributes(params[:collaborator])
      respond_with @c
    else
      raise
    end
  end

  def destroy
    @cb = Collaborator.find(params[:id])
    @cb.destroy if @cb
    respond_with @cb
  end

  protected

  def find_users
    @users = @project.collaborators.order('uname')#User.all
    @users = @users.without(@project.owner_id) if @project.owner_type == 'User'
  end

  def find_groups
    @groups = @project.groups.order('uname')#Group.all
    @groups = @groups.without(@project.owner_id) if @project.owner_type == 'Group'
  end

  def authorize_collaborators
    authorize! :update, @project
  end
end
