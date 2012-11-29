class Api::V1::MaintainersController < Api::V1::BaseController
  before_filter :authenticate_user! unless APP_CONFIG['anonymous_access']
  load_and_authorize_resource :platform

  def index
    @maintainers = BuildList::Package.actual.by_platform(@platform)
                                     .includes(:project)
    if name = params[:filter].try(:[], :package_name)
      @maintainers = @maintainers.like_name(name)
    end
    @maintainers = @maintainers.paginate(paginate_params)
  end
end
