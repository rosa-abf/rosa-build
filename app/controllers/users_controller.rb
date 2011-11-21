# coding: UTF-8
class UsersController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_user, :only => [:show, :edit, :update, :destroy]

  authorize_resource

  def index
    @users = User.paginate(:page => params[:user_page])
  end

  def show
    @groups       = @user.groups.uniq
    @platforms    = @user.platforms.paginate(:page => params[:platform_page], :per_page => 10)
    @repositories = @user.repositories.paginate(:page => params[:repository_page], :per_page => 10)
    @projects     = @user.projects.paginate(:page => params[:project_page], :per_page => 10)
  end

  def new
    @user = User.new
  end

  def edit
  end

  def create
    @user = User.new params[:user]
    if @user.save
      flash[:notice] = t('flash.user.saved')
      redirect_to users_path
    else
      flash[:error] = t('flash.user.save_error')
      render :action => :new
    end
  end

  def update
    @user.role = params[:user][:role] if current_user.admin?
    if @user.update_attributes(params[:user])
      flash[:notice] = t('flash.user.saved')
      redirect_to users_path
    else
      flash[:error] = t('flash.user.save_error')
      render :action => :edit
    end
  end

  def destroy
    @user.destroy
    flash[:notice] = t("flash.user.destroyed")
    redirect_to users_path
  end

  protected

    def find_user
      @user = User.find(params[:id])
    end
end
