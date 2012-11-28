# -*- encoding : utf-8 -*-
class Platforms::MaintainersController < ApplicationController
  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, :only => [:index] if APP_CONFIG['anonymous_access']
  load_and_authorize_resource :platform

  def index
    @maintainers = BuildList::Package.actual.by_platform(@platform)
                                     .includes(:project)
    @maintainers = @maintainers.where('name ILIKE ?', "%#{params[:q]}%") if params[:q].present?
    @maintainers = @maintainers.paginate(:page => params[:page])
  end

end
