class Platforms::MaintainersController < ApplicationController
  layout 'bootstrap'

  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, only: [:index] if APP_CONFIG['anonymous_access']
  load_and_authorize_resource :platform

  def index
    @maintainer   = BuildList::Package.new(params[:build_list_package])
    @maintainers  = BuildList::Package.includes(:project).
      actual.by_platform(@platform).
      like_name(@maintainer.name).
      paginate(page: params[:page])
  end
end
