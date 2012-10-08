# -*- encoding : utf-8 -*-
class Api::V1::PlatformsController < Api::V1::BaseController

  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, :only => [:show, :platforms_for_build] if APP_CONFIG['anonymous_access']

  load_and_authorize_resource

  def index
    @platforms = @platforms.accessible_by(current_ability, :related).
      by_type(params[:type]).paginate(:page => params[:page], :per_page => 20)
  end

  def show
  end

  def platforms_for_build
  	@platforms = Platform.main.opened.paginate(:page => params[:page], :per_page => 20)
  	render :index
  end
end
