class Api::V1::MaintainersController < Api::V1::BaseController
  before_action :authenticate_user! unless APP_CONFIG['anonymous_access']
  load_and_authorize_resource :platform

  def index
    @maintainers = BuildList::Package.includes(:project)
                                     .actual.by_platform(@platform)
                                     .like_name(params[:package_name])
                                     .paginate(paginate_params)
    respond_to :json
  end
end
