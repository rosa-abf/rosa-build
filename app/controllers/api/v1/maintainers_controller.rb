class Api::V1::MaintainersController < Api::V1::BaseController
  before_action :authenticate_user! unless APP_CONFIG['anonymous_access']

  def index
    authorize @platform = Platform.find(params[:platform_id]), :show?
    @maintainers = BuildList::Package.includes(:project)
                                     .actual.by_platform(@platform)
                                     .like_name(params[:package_name])
                                     .paginate(paginate_params)
  end
end
