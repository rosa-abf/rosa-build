# -*- encoding : utf-8 -*-
class Api::V1::GroupsController < Api::V1::BaseController
  
  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, :only => [:show] if APP_CONFIG['anonymous_access']
  load_and_authorize_resource :group

  def index
    # accessible_by(current_ability)
    @groups = current_user.groups.paginate(paginate_params)
  end

  def show
  end

  def update

  end


end