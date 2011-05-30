
class PlatformsController < ApplicationController
  before_filter :authenticate_user!

  before_filter :find_platform, :only => [:freeze, :unfreeze, :clone]

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
      @platforms = Platform.all
      render :action => :new
    end
  end

  def freeze
    @platform.released = true
    if @platform.save
      flash[:notice] = I18n.t("flash.platform.freezed")
    else
      flash[:notice] = I18n.t("flash.platform.freeze_error")
    end

    redirect_to @platform
  end

  def unfreeze
    @platform.released = false
    if @platform.save
      flash[:notice] = I18n.t("flash.platform.unfreezed")
    else
      flash[:notice] = I18n.t("flash.platform.unfreeze_error")
    end

    redirect_to @platform
  end

  def clone
    cloned = @platform.clone(@platform.name + "_clone", @platform.unixname + "_clone")
    if cloned
      flash[:notice] = 'Клонирование успешно'
      redirect_to cloned
    else
      flash[:notice] = 'Ошибка клонирования'
      redirect_to @platform
    end
  end

  def destroy
    Platform.destroy params[:id]

    flash[:notice] = t("flash.platform.destroyed")
    redirect_to root_path
  end

  protected
    def find_platform
      @platform = Platform.find params[:id]
    end
end
