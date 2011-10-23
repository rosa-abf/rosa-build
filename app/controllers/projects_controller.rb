class ProjectsController < ApplicationController
  before_filter :authenticate_user!
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
    @pls = Platform.main
    @bpls = @project.repositories.collect { |rep| ["#{rep.platform.name}/#{rep.unixname}", rep.platform.id] }
  end

  def process_build
    @arch_ids = params[:build][:arches].select{|_,v| v == "1"}.collect{|x| x[0].to_i }
    @arches = Arch.where(:id => @arch_ids)

    @branches = @project.git_repository.branches
    @branch = @branches.select{|branch| branch.name == params[:build][:branch] }.first

    @pls_ids = params[:build][:pls].select{|_,v| v == "1"}.collect{|x| x[0].to_i }
    @pls = Platform.where(:id => @pls_ids)
    
    @bpl = Platform.find params[:bpl]

    if !check_arches || !check_branches
      @arches = Arch.recent
      render :action => "build"
    else
      flash[:notice], flash[:error] = "", ""
      @arches.each do |arch|
        @pls.each do |pl|
          build_list = @project.build_lists.new(:arch => arch, :project_version => @branch.name, :pl => pl, :bpl => @bpl)
        
          if build_list.save
            flash[:notice] += t("flash.build_list.saved", :branch_name => @branch.name, :arch => arch.name, :pl => pl, :bpl => @bpl)
          else
            flash[:error] += t("flash.build_list.save_error", :branch_name => @branch.name, :arch => arch.name, :pl => pl, :bpl => @bpl)
          end
        end
      end

      redirect_to project_path(@project)
    end
  end

  def create
    @project = Project.new params[:project]
    # @project.owner = get_acter

    if @project.save
      flash[:notice] = t('flash.project.saved') 
      # redirect_to @project.owner
      redirect_to @project
    else
      flash[:error] = t('flash.project.save_error')
      render :action => :new
    end
  end

  def destroy
    @project.destroy

    flash[:notice] = t("flash.project.destroyed")
    #redirect_to platform_repository_path(@platform, @repository)
    redirect_to root_path
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
