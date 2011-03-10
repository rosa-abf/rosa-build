class ProjectsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_platform
  before_filter :find_project, :only => [:show]

  def new
    @project = @platform.projects.new
  end

  def show
  end

  def create
    @project = @platform.projects.new params[:project]
    if @project.save
      flash[:notice] = t('flash.project.saved') 
      redirect_to @platform
    else
      flash[:error] = t('flash.project.save_error')
      render :action => :new
    end
  end

  protected

    def find_platform
      @platform = Platform.find params[:platform_id]
    end

    def find_project
      @project = @platform.projects.find params[:id]
    end
end
