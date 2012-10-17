# -*- encoding : utf-8 -*-
class Api::V1::ProjectsController < Api::V1::BaseController

  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, :only => [:get_id, :show, :refs] if APP_CONFIG['anonymous_access']
  
  load_and_authorize_resource

  def index
    @projects = Project.accessible_by(current_ability, :membered).
      paginate(paginate_params)
  end

  def get_id
    if @project = Project.find_by_owner_and_name(params[:owner], params[:name])
      authorize! :show, @project
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  def show
  end

  def refs_list
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
        where(:id => p_params[:owner_id]).first
    else
      @project.owner = nil
    end
    authorize! :update, @project.owner
    create_subject @project
  end

  def members
    @members = @project.collaborators.order('uname').paginate(paginate_params)
  end

end
