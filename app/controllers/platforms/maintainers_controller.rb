class Platforms::MaintainersController < Platforms::BaseController
  before_action :authenticate_user!
  skip_before_action :authenticate_user!, only: [:index] if APP_CONFIG['anonymous_access']

  def index
    @maintainer   = BuildList::Package.new(build_list_package_params)
    @maintainers  = BuildList::Package.includes(:project).
      actual.by_platform(@platform).
      like_name(@maintainer.name).
      paginate(page: params[:page])
  end

  def build_list_package_params
    permit_params :build_list_package, :name
  end
end
