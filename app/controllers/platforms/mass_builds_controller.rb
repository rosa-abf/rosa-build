#class MassBuildsController < ApplicationController
class Platforms::MassBuildsController < Platforms::BaseController
  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, :only => [:index, :get_list] if APP_CONFIG['anonymous_access']

  load_and_authorize_resource :platform
  load_and_authorize_resource

  skip_load_and_authorize_resource :only => [:index, :create]
  skip_load_and_authorize_resource :platform, :only => [:cancel, :failed_builds_list, :publish]
  skip_authorize_resource :platform, :only => [:index, :create]

  def create
    @auto_publish_selected, @use_save_to_repository = params[:auto_publish].present?, params[:use_save_to_repository].present?
    mass_build = @platform.mass_builds.new(:arches => params[:arches],
      :auto_publish           => @auto_publish_selected,
      :use_save_to_repository => @use_save_to_repository,
      :projects_list          => params[:projects_list],
      :build_for_platform_id  => Platform.main.where(:id => params[:build_for_platform]).first.try(:id)
    )
    mass_build.user = current_user
    authorize! :create, mass_build

    if mass_build.save
      redirect_to(platform_mass_builds_path(@platform), :notice => t("flash.platform.build_all_success"))
    else
      @mass_builds = MassBuild.by_platform(@platform).order('created_at DESC').paginate(:page => params[:page], :per_page => 20)
      flash[:warning] = mass_build.errors.full_messages.join('. ')
      flash[:error] = t("flash.platform.build_all_error")
      render :index
    end
  end

  def publish
    if params[:status] == 'test_failed'
      @mass_build.publish_test_faild_builds current_user
    else
      @mass_build.publish_success_builds current_user
    end
    redirect_to(platform_mass_builds_path(@mass_build.platform), :notice => t("flash.platform.publish_success"))
  end

  def index
    @mass_builds = MassBuild.by_platform(@platform).order('created_at DESC').paginate(:page => params[:page], :per_page => 20)
    @auto_publish_selected = @use_save_to_repository = true
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
