# -*- encoding : utf-8 -*-
class Api::V1::ProjectsController < Api::V1::BaseController
  before_filter :authenticate_user!
  load_and_authorize_resource# :id_param => :project_name # to force member actions load

  def index
    @projects = Project.accessible_by(current_ability, :membered)
  end
end
