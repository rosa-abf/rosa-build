# -*- encoding : utf-8 -*-
class Projects::ProjectsController < Projects::BaseController
  before_filter :authenticate_user!
  load_and_authorize_resource :id_param => :project_name # to force member actions load

  def index
    @projects = Project.accessible_by(current_ability, :membered)
    # @projects = @projects.search(params[:query]).search_order if params[:query].present?

    #puts prepare_list(@projects).inspect
    respond_to do |format|
      format.html { @projects = @projects.recent.paginate(:page => params[:page], :per_page => 25) }
      format.json { @projects = prepare_list(@projects) }
    end
  end

  def new
    @project = Project.new
    @who_owns = :me
  end

  def edit
  end

  def create
    @project = Project.new params[:project]
    @project.owner = choose_owner
    @who_owns = (@project.owner_type == 'User' ? :me : :group)
    authorize! :update, @project.owner if @project.owner.class == Group

    if @project.save
      flash[:notice] = t('flash.project.saved')
      redirect_to @project
    else
      flash[:error] = t('flash.project.save_error')
      flash[:warning] = @project.errors.full_messages.join('. ')
      render :action => :new
    end
  end

  def update
    params[:project].delete(:maintainer_id) if params[:project][:maintainer_id].blank?
    if @project.update_attributes(params[:project])
      flash[:notice] = t('flash.project.saved')
      redirect_to @project
    else
      @project.save
      flash[:error] = t('flash.project.save_error')
      flash[:warning] = @project.errors.full_messages.join('. ')
      render :action => :edit
    end
  end

  def destroy
    @project.destroy
    flash[:notice] = t("flash.project.destroyed")
    redirect_to @project.owner
  end

  def fork
    owner = (Group.find params[:group] if params[:group].present?) || current_user
    authorize! :update, owner if owner.class == Group
    if forked = @project.fork(owner) and forked.valid?
      redirect_to forked, :notice => t("flash.project.forked")
    else
      flash[:warning] = t("flash.project.fork_error")
      flash[:error] = forked.errors.full_messages
      redirect_to @project
    end
  end

  def sections
    if request.post?
      if @project.update_attributes(params[:project])
        flash[:notice] = t('flash.project.saved')
        redirect_to sections_project_path(@project)
      else
        @project.save
        flash[:error] = t('flash.project.save_error')
      end
    end
  end

  def remove_user
    @project.relations.by_actor(current_user).destroy_all
    flash[:notice] = t("flash.project.user_removed")
    redirect_to projects_path
  end

  def autocomplete_maintainers
    term, limit = params[:term], params[:limit] || 10
    items = User.member_of_project(@project)
                .where("users.name ILIKE ? OR users.uname ILIKE ?", "%#{term}%", "%#{term}%")
                .limit(limit).map { |u| {:value => u.fullname, :label => u.fullname, :id => u.id} }
    render :json => items
  end

  protected

  def prepare_list(projects)
    res = {}

    colName = ['name']
    sort_col = params[:iSortCol_0] || 0
    sort_dir = params[:sSortDir_0] == "desc" ? 'desc' : 'asc'
    order = "#{colName[sort_col.to_i]} #{sort_dir}"

    res[:total_count] = projects.count
    projects = projects.search(params[:sSearch]).search_order if params[:sSearch].present?
    res[:filtered_count] = projects.count

    projects = projects.order(order)
    res[:projects] = if params[:iDisplayLength].present?
      start = params[:iDisplayStart].present? ? params[:iDisplayStart].to_i : 0
      length = params[:iDisplayLength].to_i
      page = start/length + 1

      projects.paginate(:page => page, :per_page => length)
    else
      projects
    end

    res
  end

  def choose_owner
    if params[:who_owns] == 'group'
      Group.find(params[:owner_id])
    else
      current_user
    end
  end
end
