class Groups::ProfileController < Groups::BaseController
  include AvatarHelper
  include PaginateHelper

  skip_before_action :authenticate_user!, only: :show if APP_CONFIG['anonymous_access']

  def index
    authorize :group
    @groups = current_user.groups.paginate(page: params[:group_page]) # accessible_by(current_ability)
    @groups = @groups.search(params[:query]) if params[:query].present?
  end

  def show
    authorize @group
    respond_to do |format|
      format.html do
        @members = @group.members.order(:uname)
      end
      format.json do
        @projects = @group.own_projects.search(params[:term]).recent
        case params[:visibility]
        when 'open'
          @projects = @projects.opened
        when 'hidden'
          @projects = @projects.by_visibilities('hidden')
          @projects = @projects.none unless policy(@group).reader?
        else
          @projects = @projects.opened unless policy(@group).reader?
        end
        @total_items  = @projects.count
        @projects     = @projects.paginate(paginate_params)
        render 'users/profile/show'
      end
    end
  end

  def new
    authorize @group = current_user.own_groups.build
  end

  def edit
    authorize @group
  end

  def create
    @group = current_user.own_groups.new
    @group.assign_attributes(group_params)
    authorize @group
    if @group.save
      flash[:notice] = t('flash.group.saved')
      redirect_to group_path(@group)
    else
      flash[:error] = t('flash.group.save_error')
      flash[:warning] = @group.errors.full_messages.join('. ')
      render action: :new
    end
  end

  def update
    authorize @group
    if @group.update_attributes(group_params)
      update_avatar(@group, params)
      flash[:notice] = t('flash.group.saved')
      redirect_to group_path(@group)
    else
      flash[:error] = t('flash.group.save_error')
      render action: :edit
    end
  end

  def destroy
    authorize @group
    @group.destroy
    flash[:notice] = t("flash.group.destroyed")
    redirect_to groups_path
  end

  def remove_user
    authorize @group
    Relation.by_actor(current_user).by_target(@group).destroy_all
    redirect_to groups_path
  end

  protected

  def group_params
    subject_params(Group, @group)
  end

  def paginate_projects(page)
    @projects.paginate(page: (page>0 ? page : nil), per_page: 24)
  end
end
