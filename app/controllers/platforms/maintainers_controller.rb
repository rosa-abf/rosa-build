class Platforms::MaintainersController < Platforms::BaseController
  before_action :authenticate_user!
  skip_before_action :authenticate_user!, only: [:index] if APP_CONFIG['anonymous_access']

  def index
    @maintainer = BuildList::Package.new(build_list_package_params)
    @packages = @platform.packages.actual.like_name(@maintainer.name)
    @projects = @platform.projects.joins(:packages).merge( @packages ).
      includes(:maintainer).group('projects.id').reorder(:name).paginate(page: params[:page])
    @packages  = @packages.where(project_id: @projects.map(&:id)).group_by(&:project_id)
  end

  def build_list_package_params
    permit_params :build_list_package, :name
  end
end
