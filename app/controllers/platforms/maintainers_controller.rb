class Platforms::MaintainersController < ApplicationController
  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, :only => [:index] if APP_CONFIG['anonymous_access']
  load_and_authorize_resource :platform

  def index
    @maintainers = BuildList::Package.includes(:project)
                                     .actual.by_platform(@platform)
                                     .like_name(params[:q])
                                     .paginate(:page => params[:page])
  end
end
