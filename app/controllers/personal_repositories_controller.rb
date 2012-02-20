# -*- encoding : utf-8 -*-
class PersonalRepositoriesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_repository#, :only => [:show, :destroy, :add_project, :remove_project, :make_private, :settings]
  before_filter :check_repository

  load_and_authorize_resource :class => Repository

  def show
    if params[:query]
      @projects = @repository.projects.recent.by_name("%#{params[:query]}%").paginate :page => params[:project_page], :per_page => 30
    else
      @projects = @repository.projects.recent.paginate :page => params[:project_page], :per_page => 30
    end
    @user = @repository.platform.owner
    @urpmi_commands = @repository.platform.urpmi_list(request.host)
  end
  
  def change_visibility
    @repository.platform.change_visibility
    
    redirect_to settings_personal_repository_path(@repository)
  end
  
  def settings
  end

  def add_project
    if params[:project_id]
      @project = current_user.own_projects.find(params[:project_id])
      unless @repository.projects.find_by_name(@project.name)
        @repository.projects << @project
        flash[:notice] = t('flash.repository.project_added')
      else
        flash[:error] = t('flash.repository.project_not_added')
      end
      redirect_to personal_repository_path(@repository)
    else
      @projects = current_user.own_projects.addable_to_repository(@repository.id).paginate(:page => params[:project_page])
      render 'projects_list'
    end
  end

  def remove_project
    @project = current_user.own_projects.find(params[:project_id])
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
