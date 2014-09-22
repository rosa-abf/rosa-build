class Platforms::MassBuildsController < Platforms::BaseController
  include DatatableHelper

  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, only: [:index, :get_list] if APP_CONFIG['anonymous_access']

  load_resource :platform
  load_and_authorize_resource :through  => :platform, :shallow  => true


  def new
    if params[:mass_build_id].present?
      @mass_build         = @platform.mass_builds.find(params[:mass_build_id]).dup
      @mass_build.arches  = Arch.where(name: @mass_build.arch_names.split(', ')).pluck(:id)
    end
    @mass_build.arches  ||= @platform.platform_arch_settings.by_default.pluck(:arch_id)
    @mass_build.arches.map!(&:to_s)
  end

  def show
  end

  def create
    @mass_build.user, @mass_build.arches = current_user, params[:arches] || []

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
    respond_to do |format|
      format.html {}
      format.json {
        @mass_builds        = @platform.mass_builds
        @total_mass_builds  = @mass_builds.count
        @mass_builds        = @mass_builds.order("id #{sort_dir}")
                                .search(params[:sSearch])
                                .paginate(page: page, per_page: per_page)
      }
    end
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
end
