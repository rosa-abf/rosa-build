# coding: UTF-8

class PlatformsController < ApplicationController
  before_filter :authenticate_user!

  before_filter :find_platform, :only => [:freeze, :unfreeze, :clone]
  before_filter :get_paths, :only => [:new, :create]

  def index
    respond_to do |format|
      format.html { @platforms = Platform.paginate(:page => params[:platform_page]) }
      format.json do
        @platforms = Platform.where(:distrib_type => 'mandriva', :visibility => 'open', :platform_type => 'main')
        render :json => {
          :platforms => @platforms.map do |p|
                          {:name => p.name,
                           :architectures => ['i586', 'x86_64'],
                           :repositories => p.repositories.map(&:name),
                           :url => "http://abs.rosalab.ru/downloads/platforms/#{p.name}/repository"}
                        end
        }
      end
    end
  end

  def show
    @platform = Platform.find params[:id], :include => :repositories
    @repositories = @platform.repositories
    @members = @platform.members.uniq
  end

  def new
    @platforms = Platform.all
    @platform = Platform.new
  end

  def create
    @platform = Platform.new params[:platform]

    @platform.owner = get_acter

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
    def get_paths
      if params[:user_id]
        @user = User.find params[:user_id]
        @platforms_path = user_platforms_path @user
        @new_platform_path = new_user_platform_path @user
      elsif params[:group_id]
        @group = Group.find params[:group_id]
        @platforms_path = group_platforms_path @group
        @new_platform_path = new_group_platform_path @group
      else
        @platforms_path = platforms_path
        @new_platform_path = new_platform_path
      end
    end

    def find_platform
      @platform = Platform.find params[:id]
    end
end
