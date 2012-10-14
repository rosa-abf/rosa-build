# -*- encoding : utf-8 -*-
class Api::V1::RepositoriesController < Api::V1::BaseController
  
  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, :only => [:show] if APP_CONFIG['anonymous_access']

  load_and_authorize_resource :repository, :through => :platform, :shallow => true

  def show
  end

  def update
    rep_params = params[:repository] || {}
    if @repository.update_attributes(rep_params)
      render_json_response @repository, 'Repository has been updated successfully'
    else
      render_validation_error @repository, 'Repository has not been updated'
    end
  end

  def add_member
    if member.present? && @repository.add_member(member)
      render_json_response @repository, "#{member.class.to_s} '#{member.id}' has been added to repository successfully"
    else
      render_validation_error @repository, 'Member has not been added to repository'
    end
  end

  def remove_member
    if member.present? && @repository.remove_member(member)
      render_json_response @repository, "#{member.class.to_s} '#{member.id}' has been removed from repository successfully"
    else
      render_validation_error @repository, 'Member has not been removed from repository'
    end
  end

  def destroy
    @repository.destroy # later with resque
    render_json_response @repository, 'Repository has been destroyed successfully'
  end

end
