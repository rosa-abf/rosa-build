class ProjectsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_platform
  before_filter :find_repository
  before_filter :find_project, :only => [:show, :destroy]

  def new
    @project = @repository.projects.new
  end

  def show
  end

  def create
    @project = @repository.projects.new params[:project]
    if @project.save
      flash[:notice] = t('flash.project.saved') 
      redirect_to [@platform, @repository]
    else
      flash[:error] = t('flash.project.save_error')
      render :action => :new
    end
  end

  def destroy
    @project.destroy

    redirect_to platform_repository_path(@platform, @repository)
  end

  protected

    def find_platform
      @platform = Platform.find params[:platform_id]
    end

    def find_repository
      @repository = @platform.repositories.find(params[:repository_id])
    end

    def find_project
      @project = @repository.projects.find params[:id]
    end
end
