# -*- encoding : utf-8 -*-
class Api::V1::PlatformsController < Platforms::BaseController

  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, :only => [:show] if APP_CONFIG['anonymous_access']

  load_and_authorize_resource

  def index
    @platforms = @platforms.accessible_by(current_ability, :related).paginate(:page => params[:page], :per_page => 20)
  end

  def show

  end
end
