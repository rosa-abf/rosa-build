# coding: UTF-8
class GroupsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_group, :only => [:show, :edit, :update, :destroy]

  authorize_resource

  def index
    @groups = Group.paginate(:page => params[:group_page])
  end

  def show
    @platforms    = @group.platforms.paginate(:page => params[:platform_page], :per_page => 10)
    @repositories = @group.repositories.paginate(:page => params[:repository_page], :per_page => 10)
    @projects     = @group.projects.paginate(:page => params[:project_page], :per_page => 10)
  end

  def new
    @group = Group.new
  end

  def edit
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

  def update
    if @group.update_attributes(params[:group])
      flash[:notice] = t('flash.group.saved')
      redirect_to groups_path
    else
      flash[:error] = t('flash.group.save_error')
      render :action => :edit
    end
  end

  def destroy
    @group.destroy
    flash[:notice] = t("flash.group.destroyed")
    redirect_to groups_path
  end

  protected

  def find_group
    @group = Group.find(params[:id])
  end
end
