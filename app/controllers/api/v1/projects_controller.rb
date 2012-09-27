# -*- encoding : utf-8 -*-
class Api::V1::ProjectsController < Api::V1::BaseController
  
  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, :only => [:get_id, :show] if APP_CONFIG['anonymous_access']
  
  load_and_authorize_resource

  def get_id
    if @project = Project.find_by_owner_and_name(params[:owner], params[:name])
      authorize! :show, @project
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  def show

  end
end
