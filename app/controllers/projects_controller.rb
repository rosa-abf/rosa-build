# -*- encoding : utf-8 -*-
class ProjectsController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource

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
      else
        @project.save
        flash[:error] = t('flash.project.save_error')
      end
      render :action => :sections
    end
  end

  def remove_user
    @project.relations.by_object(current_user).destroy_all
    flash[:notice] = t("flash.project.user_removed")
    redirect_to projects_path
  end

  def archive
    treeish = params[:treeish].presence || @project.default_branch
    format = params[:format] || 'tar'
    commit = @project.git_repository.log(treeish, nil, :max_count => 1).first
    name = "#{@project.owner.uname}-#{@project.name}#{@project.tags.include?(treeish) ? "-#{treeish}" : ''}-#{commit.id[0..19]}"
    fullname = "#{name}.#{format == 'tar' ? 'tar.gz' : 'zip'}"
    file = Tempfile.new fullname, 'tmp'
    system("cd #{@project.path}; git archive --format=#{format} --prefix=#{name}/ #{treeish} #{format == 'tar' ? ' | gzip -9' : ''} > #{file.path}")
    file.close
    send_file file.path, :disposition => 'attachment', :type => "application/#{format == 'tar' ? 'x-tar' : 'zip'}",
      :filename => fullname
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
