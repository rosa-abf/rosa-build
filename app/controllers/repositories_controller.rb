class RepositoriesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_platform

  def index
    @repositories = @platform.repositories
  end

  def show
    @repository = @platform.repositories.find params[:id], :include => :projects
    @projects = @repository.projects
  end

  def new
    @repository = @platform.repositories.new
  end

  def destroy
    Repository.destroy params[:id]
  end

  def create
    @repository = @platform.repositories.new(params[:repository])
    if @repository.save
      flash[:notice] = 'flash.repository.saved'
      redirect_to [@platform, @repository]
    else
      flash[:error] = 'flash.repository.save_error'
      render :action => :new
    end
  end

  protected

    def find_platform
      @platform = Platform.find params[:platform_id]
    end
end
