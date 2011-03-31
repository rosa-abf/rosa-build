class RepositoriesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_platform
  before_filter :find_repository, :only => [:show, :destroy]

  def show
    @projects = @repository.projects
  end

  def new
    @repository = @platform.repositories.new
  end

  def destroy
    @repository.destroy

    redirect_to platform_path(@platform)
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

    def find_repository
      @repository = @platform.repositories.find(params[:id])
    end
end
