# -*- encoding : utf-8 -*-
class Projects::ProjectsController < Projects::BaseController
  include ProjectsHelper
  before_filter :authenticate_user!
  load_and_authorize_resource :id_param => :project_name, :collection => :possible_forks # to force member actions load

  def index
    @projects = Project.accessible_by(current_ability, :membered)

    respond_to do |format|
      format.html {
        @all_projects = @projects
        @groups = current_user.groups
        @owners = User.where(:id => @projects.where(:owner_type => 'User').uniq.pluck(:owner_id))
        @projects = @projects.recent.paginate(:page => params[:page], :per_page => 25)
      }
      format.json {
        selected_groups = params[:groups] || []
        selected_owners = params[:users] || []
        @projects = prepare_list(@projects, selected_groups, selected_owners)
      }
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
    authorize! :write, @project.owner if @project.owner.class == Group

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
    authorize! :write, owner if owner.class == Group
    if forked = @project.fork(owner, params[:fork_name]) and forked.valid?
      redirect_to forked, :notice => t("flash.project.forked")
    else
      flash[:warning] = t("flash.project.fork_error")
      flash[:error] = forked.errors.full_messages.join("\n")
      redirect_to @project
    end
  end

  def possible_forks
    render :partial => 'projects/git/base/forks', :layout => false,
      :locals => { :owner => current_user, :name => (params[:name].presence || @project.name) }
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

  def preview
    render :inline => view_context.markdown(params[:text] || ''), :layout => false
  end

  def refs_list
    refs = @project.repo.branches_and_tags.map(&:name)
    @selected = (refs.include? params[:selected]) ? params[:selected] : @project.default_branch
    render :layout => false
  end

  protected

  def prepare_list(projects, groups, owners)
    res = {}

    colName = ['name']
    sort_col = params[:iSortCol_0] || 0
    sort_dir = params[:sSortDir_0] == "desc" ? 'desc' : 'asc'
    order = "#{colName[sort_col.to_i]} #{sort_dir}"

    res[:total_count] = projects.count

    if groups.present? || owners.present?
      projects = projects.by_owners(groups, owners)
    end

    projects = projects.search(params[:sSearch])

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
