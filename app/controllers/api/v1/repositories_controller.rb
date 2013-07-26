# -*- encoding : utf-8 -*-
class Api::V1::RepositoriesController < Api::V1::BaseController
  
  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, :only => [:show, :projects] if APP_CONFIG['anonymous_access']

  load_and_authorize_resource :repository, :through => :platform, :shallow => true

  def show
  end

  def projects
    @projects = @repository.projects.
      recent.paginate(paginate_params)
  end

  def update
    update_subject @repository
  end

  def add_member
    add_member_to_subject @repository
  end

  def remove_member
    remove_member_from_subject @repository
  end

  def destroy
    destroy_subject @repository
  end

  def key_pair
  end

  def start_sync
    @repository.start_sync
    render :nothing => true
  end

  def stop_sync
    @repository.stop_sync
    render :nothing => true
  end

  def add_project
    project = Project.where(:id => params[:project_id]).first
    if project
      begin
        @repository.projects << project
        render_json_response @repository, "Project '#{project.id}' has been added to repository successfully"
      rescue ActiveRecord::RecordInvalid
        render_validation_error @repository, t('flash.repository.project_not_added')
      end
    else
      render_validation_error @repository, "Project has not been added to repository"
    end
  end

  def remove_project
    project_id = params[:project_id]
    ProjectToRepository.where(:project_id => project_id, :repository_id => @repository.id).destroy_all
    render_json_response @repository, "Project '#{project_id}' has been removed from repository successfully"
  end

  def signatures
    key_pair = @repository.key_pair
    key_pair.destroy if key_pair
    key_pair = @repository.build_key_pair(params[:repository])
    key_pair.user_id = current_user.id
    if key_pair.save
      render_json_response @repository, 'Signatures have been updated for repository successfully'
    else
      render_json_response @repository, error_message(key_pair, 'Signatures have not been updated for repository'), 422
    end
  end

end