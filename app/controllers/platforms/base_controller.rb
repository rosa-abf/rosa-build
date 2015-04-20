class Platforms::BaseController < ApplicationController
  before_action :load_platform

protected

  def load_platform
    return unless params[:platform_id]
    authorize @platform = Platform.find_cached(params[:platform_id]), :show?
  end

end
