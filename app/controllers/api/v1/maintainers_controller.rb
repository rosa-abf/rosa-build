class Api::V1::MaintainersController < Api::V1::BaseController
  before_filter :authenticate_user! unless APP_CONFIG['anonymous_access']
  before_filter :find_platform

  def index
    @maintainers = BuildList::Package.actual.by_platform(@platform)
                                     .order('lower(name) ASC, length(name) ASC')
                                     .includes(:project)
                                     .paginate(paginate_params)
  end

  private

  def find_platform
    @platform = Platform.find(params[:platform_id])
  end

end
