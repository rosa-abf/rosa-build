class Api::V1::PlatformsController < Api::V1::BaseController
  before_action :authenticate_user!
  skip_before_action :authenticate_user!, only: :allowed
  skip_before_action :authenticate_user!, only: [:show, :platforms_for_build, :members] if APP_CONFIG['anonymous_access']
  before_action :load_platform, except: [:index, :allowed, :platforms_for_build, :create]

  def allowed
    authorize :platform
    if request.authorization.present?
      token, pass = *ActionController::HttpAuthentication::Basic::user_name_and_password(request)
    end
    if Platform.allowed?(params[:path] || '', token)
      render nothing: true
    else
      render nothing: true, status: 403
    end
  end

  def index
    authorize :platform
    @platforms = PlatformPolicy::Scope.new(current_user, Platform).show.
      by_type(params[:type]).paginate(paginate_params)
  end

  def show
  end

  def platforms_for_build
    authorize :platform
    @platforms = Platform.availables_main_platforms(current_user).paginate(paginate_params)
    render :index
  end

  def create
    pp = params[:platform] || {}
    owner = User.find_by(id: pp[:owner_id])
    @platform       = Platform.new(platform_params)
    @platform.owner = owner || get_owner
    create_subject @platform
  end

  def update
    pp = params[:platform] || {}
    owner = User.find_by(id: pp[:owner_id])
    pp[:owner] = owner if owner
    update_subject @platform
  end

  def members
    @members = @platform.members.order('name').paginate(paginate_params)
  end

  def add_member
    add_member_to_subject @platform
  end

  def remove_member
    remove_member_from_subject @platform
  end

  def clone
    platform_params = params[:platform] || {}
    platform_params[:owner] = current_user
    @cloned = @platform.full_clone(platform_params)
    if @cloned.persisted?
      render_json_response @platform, 'Platform has been cloned successfully'
    else
      render_validation_error @platform, 'Platform has not been cloned'
    end
  end

  def clear
    @platform.clear
    render_json_response @platform, 'Platform has been cleared successfully'
  end

  def destroy
    destroy_subject @platform
  end

  private

  def platform_params
    subject_params(Platform)
  end

  # Private: before_action hook which loads Platform.
  def load_platform
    authorize @platform = Platform.find(params[:id])
  end

end
