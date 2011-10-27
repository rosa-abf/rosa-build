class PersonalRepositoriesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_repository#, :only => [:show, :destroy, :add_project, :remove_project, :make_private, :settings]

  def show
    if params[:query]
      @projects = @repository.projects.recent.by_name(params[:query]).paginate :page => params[:project_page], :per_page => 30
    else
      @projects = @repository.projects.recent.paginate :page => params[:project_page], :per_page => 30
    end
  end
  
  #TODO: Add git repo move into private repos path.
  def change_visibility
    @repository.change_visibility
    
    redirect_to settings_personal_repository_path(@repository)
  end
  
  def settings
    if @repository.hidden?
      @urmpi_command = "urpmi -add  http://login@password:#{ request.host }/privates/#{ @repository.platform.name }/main/"
    else
      @urmpi_command = "urpmi -add  http://#{ request.host }/downloads/#{ @repository.platform.name }/main/"
    end
  end

  def add_project
    if params[:project_id]
      @project = Project.find(params[:project_id])
      params[:project_id] = nil
      unless @repository.projects.include? @project
        @repository.projects << @project
          flash[:notice] = t('flash.repository.project_added')
          redirect_to platform_repository_path(@repository.platform, @repository)
      else
        flash[:error] = t('flash.repository.project_not_added')
        redirect_to url_for(:action => :add_project)
      end
    else
      @projects = Project.addable_to_repository(@repository.id).paginate(:page => params[:project_page])
      render 'projects_list'
    end
  end

  def remove_project
    if params[:project_id]
      @project = Project.find(params[:project_id])
      params[:project_id] = nil
      if @repository.projects.include? @project
        @repository.projects.delete @project
          flash[:notice] = t('flash.repository.project_removed')
          redirect_to platform_repository_path(@repository.platform, @repository)
      else
        redirect_to url_for(:action => :remove_project)
      end
    else
      redirect_to platform_repository_path(@repository.platform, @repository)
    end
  end

  protected

  def find_repository
    @repository = Repository.find(params[:id])
  end
end
