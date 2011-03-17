class PlatformsController < ApplicationController
  before_filter :authenticate_user!

  def index
    @platforms = Platform.all
  end

  def show
    @platform = Platform.find params[:id], :include => :repositories
    @repositories = @platform.repositories
  end

  def new
    @platforms = Platform.all
    @platform = Platform.new
  end

  def create
    @platform = Platform.new params[:platform]
    if @platform.save
      flash[:notice] = I18n.t("flash.platform.saved")
      redirect_to @platform
    else
      flash[:error] = I18n.t("flash.platform.saved_error")
      render :action => :new
    end
  end



  def destroy
    Platform.destroy params[:id]
    redirect_to root_path
  end
end
