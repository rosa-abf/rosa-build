# coding: UTF-8

class GroupsController < ApplicationController
  before_filter :authenticate_user!

  before_filter :find_group, :only => [:show, :edit, :update, :destroy]

  def index
    @groups = Group.paginate(:page => params[:page], :per_page => 15)
  end

  def show
    @platforms    = @group.platforms.paginate(:page => params[:platform_page], :per_page => 10)
    @repositories = @group.repositories.paginate(:page => params[:repository_page], :per_page => 10)
    @projects     = @group.projects.paginate(:page => params[:project_page], :per_page => 10)
  end

  def edit
  end

  def destroy
    @user.destroy

    flash[:notice] = t("flash.group.destroyed")
    redirect_to groups_path
  end

  def new
    @group = Group.new
  end

  def create
    @group = Group.new params[:group]
    @group.owner = current_user
    @group.members << current_user
    if @group.save
      flash[:notice] = t('flash.group.saved')
      redirect_to edit_group_path(@group)
    else
      flash[:error] = t('flash.group.save_error')
      render :action => :new
    end
  end

  private
  def find_group
    @group = Group.find(params[:id])
  end

end
