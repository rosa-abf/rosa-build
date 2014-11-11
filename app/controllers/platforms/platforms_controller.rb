class Platforms::PlatformsController < Platforms::BaseController
  include FileStoreHelper
  layout 'bootstrap'

  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, only: [:advisories, :members, :show] if APP_CONFIG['anonymous_access']
  load_and_authorize_resource

  def index
    respond_to do |format|
      format.html {}

      format.json {
        @platforms = @platforms.accessible_by(current_ability, :related)
        @platforms_count = @platforms.count
        @platforms = @platforms.paginate(page: current_page, per_page: Platform.per_page)
      }
    end
  end

  def show
  end

  def new
    @admin_uname  = current_user.uname
    @admin_id     = current_user.id
    @platform     = Platform.new
  end

  def edit
    @admin_id = @platform.owner.id
    @admin_uname = @platform.owner.uname
  end

  def create
    @admin_id = params[:admin_id]
    @admin_uname = params[:admin_uname]
    # FIXME: do not allow manipulate owner model, only platforms onwer_id and onwer_type
    @platform.owner = @admin_id.blank? ? get_owner : User.find(@admin_id)

    if @platform.save
      flash[:notice] = I18n.t("flash.platform.created")
      redirect_to @platform
    else
      flash[:error] = I18n.t("flash.platform.create_error")
      render action: :new
    end
  end

  def update
    @admin_id = params[:admin_id]
    @admin_uname = params[:admin_uname]

    platform_params = params[:platform] || {}
    platform_params = platform_params.slice(:description, :platform_arch_settings_attributes, :released, :automatic_metadata_regeneration)
    platform_params[:owner] = User.find(@admin_id) if @admin_id.present?


    respond_to do |format|
      format.html do
        if @platform.update_attributes(platform_params)
          flash[:notice] = I18n.t("flash.platform.saved")
          redirect_to @platform
        else
          flash[:error] = I18n.t("flash.platform.save_error")
          render action: :edit
        end
      end
      format.json do
        if @platform.update_attributes(platform_params)
          render json: { notice: I18n.t("flash.platform.saved") }.to_json
        else
          render json: { error: I18n.t("flash.platform.save_error") }.to_json, status: 422
        end
      end
    end
  end

  def regenerate_metadata
    if @platform.regenerate
      flash[:notice] = I18n.t('flash.platform.saved')
    else
      flash[:error] = I18n.t('flash.platform.save_error')
    end
    redirect_to edit_platform_path(@platform)
  end

  def change_visibility
    if @platform.change_visibility
      flash[:notice] = I18n.t("flash.platform.saved")
      redirect_to @platform
    else
      flash[:error] = I18n.t("flash.platform.save_error")
      flash[:warning] = @platform.errors.full_messages.join('. ')
      render action: :edit
    end
  end

  def clone
    @cloned = Platform.new
    @cloned.name = @platform.name + "_clone"
    @cloned.description = @platform.description + "_clone"
  end

  def make_clone
    @cloned = @platform.full_clone params[:platform].merge(owner: current_user)
    if @cloned.persisted?
      flash[:notice] = I18n.t("flash.platform.clone_success")
      redirect_to @cloned
    else
      flash[:error] = @cloned.errors.full_messages.join('. ')
      render 'clone'
    end
  end

  def destroy
    @platform.destroy # later with resque
    flash[:notice] = t("flash.platform.destroyed")
    redirect_to platforms_path
  end

  def members
    @members = @platform.members.order(:uname)
  end

  def remove_members
    User.where(id: params[:members]).each do |user|
      @platform.remove_member(user)
    end
    redirect_to members_platform_path(@platform)
  end

  def add_member
    member = User.where(id: params[:member_id]).first
    if !member
      flash[:error] = t("flash.collaborators.wrong_user", uname: params[:member_id])
    elsif @platform.add_member(member)
      flash[:notice] = t('flash.platform.members.successfully_added', name: member.uname)
    else
      flash[:error] = t('flash.platform.members.error_in_adding', name: member.uname)
    end
    redirect_to members_platform_url(@platform)
  end

  def advisories
    @advisories = @platform.advisories.paginate(page: params[:page])
  end

  def clear
    @platform.clear
    flash[:notice] = t('flash.repository.clear')
    redirect_to edit_platform_path(@platform)
  end

end
