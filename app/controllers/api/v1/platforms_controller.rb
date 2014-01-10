class Api::V1::PlatformsController < Api::V1::BaseController
  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, :only => :allowed
  skip_before_filter :authenticate_user!, :only => [:show, :platforms_for_build, :members] if APP_CONFIG['anonymous_access']

  load_and_authorize_resource :except => :allowed

  def allowed
    if Platform.allowed?(params[:path] || '', request)
      render :nothing => true
    else
      render :nothing => true, :status => 403
    end
  end

  def index
    @platforms = @platforms.accessible_by(current_ability, :related).
      by_type(params[:type]).paginate(paginate_params)
  end

  def show
  end

  def platforms_for_build
  	@platforms = Platform.main.opened.paginate(paginate_params)
  	render :index
  end

  def create
    platform_params = params[:platform] || {}
    owner = User.where(:id => platform_params[:owner_id]).first
    @platform.owner = owner || get_owner
    create_subject @platform
  end

  def update
    platform_params = params[:platform] || {}
    owner = User.where(:id => platform_params[:owner_id]).first
    platform_params[:owner] = owner if owner
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

end
