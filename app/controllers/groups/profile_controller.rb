# -*- encoding : utf-8 -*-
class Groups::ProfileController < Groups::BaseController
  load_and_authorize_resource :class => Group, :instance_name => 'group'

  autocomplete :group, :uname

  def index
    @groups = current_user.groups.paginate(:page => params[:group_page]) # accessible_by(current_ability)
    @groups = @groups.search(params[:query]) if params[:query].present?
  end

  def show
    @projects = @group.projects #.paginate(:page => params[:project_page], :per_page => 10)
  end

  def new
  end

  def edit
  end

  def create
    @group = Group.new params[:group]
    @group.owner = current_user
    if @group.save
      flash[:notice] = t('flash.group.saved')
      redirect_to group_path(@group)
    else
      flash[:error] = t('flash.group.save_error')
      flash[:warning] = @group.errors.full_messages.join('. ')
      render :action => :new
    end
  end

  def update
    if @group.update_attributes(params[:group])
      flash[:notice] = t('flash.group.saved')
      redirect_to group_path(@group)
    else
      flash[:error] = t('flash.group.save_error')
      render :action => :edit
    end
  end

  def destroy
    @group.destroy
    flash[:notice] = t("flash.group.destroyed")
    redirect_to groups_path
  end

  def remove_user
    Relation.by_actor(current_user).by_target(@group).destroy_all
    redirect_to groups_path
  end
end
