class PlatformsController < ApplicationController
  before_filter :authenticate_user!

  def index
    @platforms = Platform.all
  end

  def show
    @platform = Platform.find params[:id], :include => :projects
    @projects = @platform.projects
  end

  def new
    @platforms = Platform.all
    @platform = Platform.new
  end

  def edit
    @platform = Platform.find params[:id]
  end

  def create
    @platform = Platform.new params[:platform]
    if @platform.save
      flash[:notice] = 'Платформа успешно добавлена'
      redirect_to @platform
    else
      flash[:error] = 'Не удалось создать платформу'
      render :action => :new
    end
  end

  def update
    @platform = Platform.find params[:id]
    if @platform.update_attributes(params[:platform])
      flash[:notice] = 'Платформа успешно обновлена'
      redirect_to @platform
    else
      flash[:error] = 'Не удалось обновить платформу'
      render :action => :edit
    end
  end

  def destroy
    Platform.destroy params[:id]
    redirect_to root_path
  end
end
