class RepositoriesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_platform
  before_filter :find_repository, :only => [:show, :destroy]

  def show
    if params[:query]
      @projects = @repository.projects.recent.by_name(params[:query]).paginate :page => params[:page], :per_page => 30
    else
      @projects = @repository.projects.recent.paginate :page => params[:page], :per_page => 30
    end
  end

  def new
    @repository = @platform.repositories.new
  end

  def destroy
    @repository.destroy

    flash[:notice] = t("flash.repository.destroyed")
    redirect_to platform_path(@platform)
  end

  def create
    @repository = @platform.repositories.new(params[:repository])
    if @repository.save
      flash[:notice] = t('flash.repository.saved')
      redirect_to [@platform, @repository]
    else
      flash[:error] = t('flash.repository.save_error')
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
