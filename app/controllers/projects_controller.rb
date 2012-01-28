class ProjectsController < ApplicationController
  is_related_controller!

  belongs_to :user, :group, :polymorphic => true, :optional => true

  before_filter :authenticate_user!, :except => :auto_build
  before_filter :find_project, :only => [:show, :edit, :update, :destroy, :fork]
  before_filter :get_paths, :only => [:new, :create, :edit, :update]

  load_and_authorize_resource

  def index
    @projects = if parent? and !parent.nil?
                  parent.projects
                else
                  Project
                end.accessible_by(current_ability)

    @projects = if params[:query]
                  @projects.by_name("%#{params[:query]}%").order("CHAR_LENGTH(name) ASC")
                else
                  @projects
                end.paginate(:page => params[:project_page])

    @own_projects = current_user.own_projects
    @part_projects = current_user.projects + current_user.groups.map(&:projects).flatten.uniq - @own_projects
  end

  def show
    @current_build_lists = @project.build_lists.current.recent.paginate :page => params[:page]
  end

  def new
    @project = Project.new
  end

  def edit
  end

  def create
    @project = Project.new params[:project]
    @project.owner = get_owner
#    puts @project.owner.inspect

    if @project.save
      flash[:notice] = t('flash.project.saved') 
      redirect_to @project
    else
      flash[:error] = t('flash.project.save_error')
      flash[:warning] = @project.errors[:base]
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
      render :action => :edit
    end
  end

  def destroy
    @project.destroy
    flash[:notice] = t("flash.project.destroyed")
    redirect_to @project.owner
  end

  def fork
    if forked = @project.fork(current_user) and forked.valid?
      redirect_to forked, :notice => t("flash.project.forked")
    else
      flash[:warning] = t("flash.project.fork_error")
      flash[:error] = forked.errors.full_messages
      redirect_to @project
    end
  end

  # TODO remove this?
  def auto_build
    uname, name = params[:git_repo].split('/')
    owner = User.find_by_uname(uname) || Group.find_by_uname(uname)
    project = Project.where(:owner_id => owner.id, :owner_type => owner.class).find_by_name!(name)
    project.delay.auto_build # TODO don't queue duplicates

    # p = params.delete_if{|k,v| k == 'controller' or k == 'action'}
    # ActiveSupport::Notifications.instrument("event_log.observer", :object => project, :message => p.inspect)
    logger.info "Git hook recieved from #{params[:git_user]} to #{params[:git_repo]}"

    render :nothing => true
  end

  protected

    def get_paths
      if params[:user_id]
        @user = User.find params[:user_id]
        @projects_path = user_path(@user) # user_projects_path @user
        @new_project_path = new_user_project_path @user
      elsif params[:group_id]
        @group = Group.find params[:group_id]
        @projects_path = group_path(@group) # group_projects_path @group
        @new_projects_path = new_group_project_path @group
      else
        @projects_path = projects_path
        @new_projects_path = new_project_path
      end
    end

    def find_project
      @project = Project.find params[:id]
    end
end
