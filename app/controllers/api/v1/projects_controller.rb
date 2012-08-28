# -*- encoding : utf-8 -*-
class Api::V1::ProjectsController < Api::V1::BaseController
  before_filter :authenticate_user!
  load_and_authorize_resource

  def get_id
    if @project = Project.find_by_owner_and_name(params[:owner], params[:name])
      authorize! :show, @project
    else
      render :json => {:message => t("flash.404_message")}.to_json
    end
  end
end
