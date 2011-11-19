class PersonalRepositoriesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_repository#, :only => [:show, :destroy, :add_project, :remove_project, :make_private, :settings]
  before_filter :check_repository
  
  #authorize_resource

  def show
    authorize! :read, @repository

    if params[:query]
      @projects = @repository.projects.recent.by_name(params[:query]).paginate :page => params[:project_page], :per_page => 30
    else
      @projects = @repository.projects.recent.paginate :page => params[:project_page], :per_page => 30
    end
    
    @urpmi_commands = @repository.platform.urpmi_list(request.host)
  end
  
  def change_visibility
    authorize! :change_visibility, @repository

    @repository.platform.change_visibility
    
    redirect_to settings_personal_repository_path(@repository)
  end
  
  def settings
    authorize! :settings, @repository
  end

  def add_project
    authorize! :add_project, @repository

    if params[:project_id]
      @project = Project.find(params[:project_id])
      # params[:project_id] = nil
      unless @repository.projects.find_by_unixname(@project.unixname)
        @repository.projects << @project
        flash[:notice] = t('flash.repository.project_added')
      else
        flash[:error] = t('flash.repository.project_not_added')
      end
      redirect_to personal_repository_path(@repository)
    else
      @projects = Project.addable_to_repository(@repository.id).paginate(:page => params[:project_page])
      render 'projects_list'
    end
  end

  def remove_project
    authorize! :remove_project, @repository
    
    @project = Project.find(params[:project_id])
    ProjectToRepository.where(:project_id => @project.id, :repository_id => @repository.id).destroy_all
    redirect_to personal_repository_path(@repository), :notice => t('flash.repository.project_removed')
  end

  protected

  def find_repository
    @repository = Repository.find(params[:id])
  end
  
  def check_repository
    redirect_to root_path if !@repository.platform.personal?
  end
end
