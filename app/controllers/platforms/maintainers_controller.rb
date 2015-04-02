class Platforms::MaintainersController < Platforms::BaseController
  before_action :authenticate_user!
  skip_before_action :authenticate_user!, only: [:index] if APP_CONFIG['anonymous_access']

  def index
    @maintainer   = BuildList::Package.new(params[:build_list_package])
    @maintainers  = BuildList::Package.includes(:project).
      actual.by_platform(@platform).
      like_name(@maintainer.name).
      paginate(page: params[:page])
  end
end
