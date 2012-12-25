#class MassBuildsController < ApplicationController
class Platforms::MassBuildsController < Platforms::BaseController
  before_filter :authenticate_user!

  load_and_authorize_resource :platform
  load_and_authorize_resource

  skip_load_and_authorize_resource :only => [:index, :create]
  skip_load_and_authorize_resource :platform, :only => [:cancel, :failed_builds_list]
  skip_authorize_resource :platform, :only => [:create, :index]

  def create
    mass_build = @platform.mass_builds.new(:arches => params[:arches],
      :auto_publish => params[:auto_publish] || false,
      :projects_list => params[:projects_list],
      :new_core => params[:new_core])
    mass_build.user = current_user
    authorize! :create, mass_build

    if mass_build.save
      redirect_to(platform_mass_builds_path(@platform), :notice => t("flash.platform.build_all_success"))
    else
      @auto_publish_selected = params[:auto_publish].present?
      @mass_builds = MassBuild.by_platform(@platform).order('created_at DESC').paginate(:page => params[:page], :per_page => 20)
      flash[:warning] = mass_build.errors.full_messages.join('. ')
      flash[:error] = t("flash.platform.build_all_error")
      render :index
    end
  end

  def index
    authorize! :edit, @platform

    @mass_builds = MassBuild.by_platform(@platform).order('created_at DESC').paginate(:page => params[:page], :per_page => 20)
    @auto_publish_selected = true
  end

  def cancel
    @mass_build.cancel_all
    flash[:notice] = t("flash.platform.cancel_mass_build")
    redirect_to platform_mass_builds_path(@mass_build.platform)
  end

  def get_list
    text = if params[:kind] == 'failed_builds_list'
                @mass_build.generate_failed_builds_list
              elsif ['projects_list', 'missed_projects_list'].include? params[:kind]
                 @mass_build.send params[:kind]
              end
    render :text => text
  end
end
