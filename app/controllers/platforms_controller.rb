# coding: UTF-8
class PlatformsController < ApplicationController
  before_filter :authenticate_user!, :except => :easy_urpmi
  before_filter :find_platform, :only => [:freeze, :unfreeze, :clone, :edit]
  before_filter :get_paths, :only => [:new, :create]
  before_filter :check_global_access, :except => :easy_urpmi

  def index
    @platforms = Platform.visible_to(current_user).paginate(:page => params[:platform_page])
  end

  def easy_urpmi
    @platforms = Platform.where(:distrib_type => 'mandriva2011', :visibility => 'open', :platform_type => 'main')
    respond_to do |format|
      format.json do
        render :json => {
          :platforms => @platforms.map do |p|
                          {:name => p.unixname,
                           :architectures => ['i586', 'x86_64'],
                           :repositories => p.repositories.map(&:unixname),
                           :url => "http://#{request.host_with_port}/downloads/platforms/#{p.unixname}/repository"}
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
    @platforms = Platform.visible_to current_user
    @platform = Platform.new
  end
  
  def edit
    @platforms = Platform.visible_to current_user
  end

  def create
    @platform = Platform.new params[:platform]

    @platform.owner = get_owner

    if @platform.save
      flash[:notice] = I18n.t("flash.platform.saved")
      redirect_to @platform
    else
      flash[:error] = I18n.t("flash.platform.saved_error")
      @platforms = Platform.visible_to current_user
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
