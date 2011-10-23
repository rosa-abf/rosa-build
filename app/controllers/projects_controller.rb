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
    @project_versions = @project.project_versions
    @arches = Arch.recent
    @pls = Platform.main
    @bpls = @project.repositories.collect { |rep| ["#{rep.platform.name}/#{rep.unixname}", rep.platform.id] }
    @project_versions = @project.project_versions.collect { |tag| [tag.name.gsub(/^\w+\./, ""), tag.name] }.select { |pv| pv[1] =~ /^v\./  }
  end

  def process_build
    @arch_ids = params[:build][:arches].select{|_,v| v == "1"}.collect{|x| x[0].to_i }
    @arches = Arch.where(:id => @arch_ids)

    #@project_versions = @project.git_repository.project_versions
    #@project_version = @project_versions.select{|project_version| project_version.name == params[:build][:project_version] }.first
    @project_version = params[:build][:project_version]

    @pls_ids = params[:build][:pls].select{|_,v| v == "1"}.collect{|x| x[0].to_i }
    @pls = Platform.where(:id => @pls_ids)
    
    @bpl = Platform.find params[:build][:bpl]
    
    @project_version = params[:build][:project_version]

    if !check_arches || !check_project_versions
      @arches = Arch.recent
      render :action => "build"
    else
      flash[:notice], flash[:error] = "", ""
      @arches.each do |arch|
        @pls.each do |pl|
          build_list = @project.build_lists.new(:arch => arch, :project_version => @project_version, :pl => pl, :bpl => @bpl)
        
          if build_list.save
            flash[:notice] += t("flash.build_list.saved", :project_version => @project_version, :arch => arch.name, :pl => pl, :bpl => @bpl)
          else
            flash[:error] += t("flash.build_list.save_error", :project_version => @project_version, :arch => arch.name, :pl => pl, :bpl => @bpl)
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

    def check_project_versions
      if @project_version.blank?
        flash[:error] = t("flash.build_list.no_project_version_selected")
        false
      elsif !@project_versions.include?(@project_version)
        flash[:error] = t("flash.build_list.no_project_version_found")
        false
      else
        true
      end
    end
end
