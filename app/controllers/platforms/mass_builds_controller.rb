class Platforms::MassBuildsController < Platforms::BaseController
  include DatatableHelper

  before_action :authenticate_user!
  skip_before_action :authenticate_user!, only: [:index, :get_list] if APP_CONFIG['anonymous_access']

  before_action :find_mass_build, only: %i(show publish cancel get_list)

  def new
    if params[:mass_build_id].present?
      @mass_build         = @platform.mass_builds.find(params[:mass_build_id]).dup
      @mass_build.arches  = Arch.where(name: @mass_build.arch_names.split(', ')).pluck(:id)
    end
    authorize @mass_build     ||= @platform.mass_builds.build
    @mass_build.arches        ||= @platform.platform_arch_settings.by_default.pluck(:arch_id)
    @mass_build.repositories  ||= []
    @mass_build.arches.map!(&:to_s)
  end

  def show
    authorize @platform.mass_builds.find(params[:id])
  end

  def create
    @mass_build                 = @platform.mass_builds.build(subject_params(MassBuild))
    @mass_build.user            = current_user
    @mass_build.arches          = params[:arches] || []
    @mass_build.repositories  ||= params[:repositories] || []

    authorize @mass_build
    if @mass_build.save
      redirect_to(platform_mass_builds_path(@platform), notice: t("flash.platform.build_all_success"))
    else
      flash[:warning] = @mass_build.errors.full_messages.join('. ')
      flash[:error] = t('flash.platform.build_all_error')
      render action: :new
    end
  end

  def publish
    if params[:status] == 'test_failed'
      @mass_build.publish_test_failed_builds current_user
    else
      @mass_build.publish_success_builds current_user
    end
    redirect_to(platform_mass_builds_path(@mass_build.save_to_platform), notice: t("flash.platform.publish_success"))
  end

  def index
    @mass_build  = MassBuild.new(params[:mass_build])
    @mass_builds = @platform.mass_builds.search(@mass_build.description).
      order(id: :desc).paginate(page: params[:page])
  end

  def cancel
    @mass_build.cancel_all
    flash[:notice] = t("flash.platform.cancel_mass_build")
    redirect_to platform_mass_builds_path(@mass_build.save_to_platform)
  end

  def get_list
    text =
      case params[:kind]
      when 'failed_builds_list', 'tests_failed_builds_list', 'success_builds_list'
        @mass_build.send "generate_#{params[:kind]}"
      when 'projects_list', 'missed_projects_list'
        @mass_build.send params[:kind]
      end
    render text: text
  end

  private

  # Private: before_action hook which loads MassBuild.
  def find_mass_build
    authorize @mass_build = @platform.mass_builds.find(params[:id])
  end
end
