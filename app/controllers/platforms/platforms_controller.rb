class Platforms::PlatformsController < Platforms::BaseController
  include FileStoreHelper

  before_action :authenticate_user!
  skip_before_action :authenticate_user!, only: [:advisories, :members, :show] if APP_CONFIG['anonymous_access']

  def index
    authorize :platform
    respond_to do |format|
      format.html {}

      format.json {
        @platforms = PlatformPolicy::Scope.new(current_user, Platform).related
        @platforms_count = @platforms.count
        @platforms = @platforms.paginate(page: current_page, per_page: Platform.per_page)
      }
    end
  end

  def show
  end

  def new
    authorize @platform = Platform.new
    @admin_uname  = current_user.uname
    @admin_id     = current_user.id
  end

  def edit
    authorize @platform
    @admin_id = @platform.owner.id
    @admin_uname = @platform.owner.uname
  end

  def create
    authorize @platform = Platform.new(platform_params)
    @admin_id    = params[:admin_id]
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
    authorize @platform
    @admin_id = params[:admin_id]
    @admin_uname = params[:admin_uname]

    pp = platform_params
    pp[:owner] = User.find(@admin_id) if @admin_id.present?

    respond_to do |format|
      format.html do
        if @platform.update_attributes(pp)
          flash[:notice] = I18n.t("flash.platform.saved")
          redirect_to @platform
        else
          flash[:error] = I18n.t("flash.platform.save_error")
          render action: :edit
        end
      end
      format.json do
        if @platform.update_attributes(pp)
          render json: { notice: I18n.t("flash.platform.saved") }.to_json
        else
          render json: { error: I18n.t("flash.platform.save_error") }.to_json, status: 422
        end
      end
    end
  end

  def regenerate_metadata
    authorize @platform
    if @platform.regenerate
      flash[:notice] = I18n.t('flash.platform.saved')
    else
      flash[:error] = I18n.t('flash.platform.save_error')
    end
    redirect_to edit_platform_path(@platform)
  end

  def change_visibility
    authorize @platform
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
    authorize @platform
    @cloned = Platform.new
    @cloned.name = @platform.name + "_clone"
    @cloned.description = @platform.description + "_clone"
  end

  def make_clone
    authorize @platform
    @cloned = @platform.full_clone platform_params.merge(owner: current_user)
    if @cloned.persisted?
      flash[:notice] = I18n.t("flash.platform.clone_success")
      redirect_to @cloned
    else
      flash[:error] = @cloned.errors.full_messages.join('. ')
      render 'clone'
    end
  end

  def destroy
    authorize @platform
    @platform.destroy # later with resque
    flash[:notice] = t("flash.platform.destroyed")
    redirect_to platforms_path
  end

  def members
    authorize @platform
    @members = @platform.members.order(:uname)
  end

  def remove_members
    authorize @platform
    User.where(id: params[:members]).each do |user|
      @platform.remove_member(user)
    end
    redirect_to members_platform_path(@platform)
  end

  def add_member
    authorize @platform
    member = User.find_by(id: params[:member_id])
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
    authorize @platform
    @advisories = @platform.advisories.paginate(page: params[:page])
  end

  def clear
    authorize @platform
    @platform.clear
    flash[:notice] = t('flash.repository.clear')
    redirect_to edit_platform_path(@platform)
  end

  private

  def platform_params
    subject_params(Platform)
  end

  # Private: before_action hook which loads Platform.
  def load_platform
    authorize @platform = Platform.find_cached(params[:id]), :show? if params[:id]
  end

end
