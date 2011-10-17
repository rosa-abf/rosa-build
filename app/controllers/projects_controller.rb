class ProjectsController < ApplicationController
  before_filter :authenticate_user!
#  before_filter :find_platform
#  before_filter :find_repository
  before_filter :find_project, :only => [:show, :destroy, :build, :process_build]
  before_filter :get_paths, :only => [:new, :create]

  def new
    @project = Project.new
  end

  def show
    @current_build_lists = @project.build_lists.current.recent.paginate :page => params[:page]
  end

  def build
    @branches = @project.git_repository.branches
    @arches = Arch.recent
  end

  def process_build
    @arch_ids = params[:build][:arches].select{|_,v| v == "1"}.collect{|x| x[0].to_i }
    @arches = Arch.where(:id => @arch_ids)

    @branches = @project.git_repository.branches
    @branch = @branches.select{|branch| branch.name == params[:build][:branch] }.first

    if !check_arches || !check_branches
      @arches = Arch.recent
      render :action => "build"
    else
      flash[:notice], flash[:error] = "", ""
      @arches.each do |arch|
        build_list = @project.build_lists.new(:arch => arch, :branch_name => @branch.name)
        
        if build_list.save
          flash[:notice] += t("flash.build_list.saved", :branch_name => @branch.name, :arch => arch.name)
        else
          flash[:error] += t("flash.build_list.save_error", :branch_name => @branch.name, :arch => arch.name)
        end
      end

      redirect_to platform_repository_project_path(@platform, @repository, @project)
    end
  end

  def create
    @project = Project.new params[:project]
    @project.owner = get_acter

    if @project.save
      flash[:notice] = t('flash.project.saved') 
      redirect_to @project.owner
    else
      flash[:error] = t('flash.project.save_error')
      render :action => :new
    end
  end

  def destroy
    @project.destroy

    flash[:notice] = t("flash.project.destroyed")
    redirect_to platform_repository_path(@platform, @repository)
  end

  protected

    def get_paths
      if params[:user_id]
        @user = User.find params[:user_id]
        @projects_path = user_projects_path @user
        @new_project_path = new_user_project_path @user
      elsif params[:group_id]
        @group = Group.find params[:group_id]
        @projects_path = group_projects_path @group
        @new_projects_path = new_group_project_path @group
      else
        @projects_path = projects_path
        @new_projects_path = new_project_path
      end
    end

    def find_platform
      @platform = Platform.find params[:platform_id]
    end

    def find_repository
      @repository = @platform.repositories.find(params[:repository_id])
    end

    def find_project
      @project = Project.find params[:id]
    end

    def check_arches
      if @arch_ids.blank?
        flash[:error] = t("flash.build_list.no_arch_selected")
        false
      elsif @arch_ids.length != @arches.length
        flash[:error] = t("flash.build_list.no_arch_found")
        false
      else
        true
      end
    end

    def check_branches
      if @branch.blank?
        flash[:error] = t("flash.build_list.no_branch_selected")
        false
      elsif !@branches.include?(@branch)
        flash[:error] = t("flash.build_list.no_branch_found")
        false
      else
        true
      end
    end
end
