class MassBuildsController < ApplicationController
  before_filter :authenticate_user!

  load_and_authorize_resource

  def cancel_mass_build
    @mass_build.cancel_all
    flash[:notice] = t("flash.platform.cancel_mass_build")
    redirect_to mass_builds_platform_path(@mass_build.platform)
  end

  def failed_builds_list
    render :text => @mass_build.generate_failed_builds_list
  end
end
