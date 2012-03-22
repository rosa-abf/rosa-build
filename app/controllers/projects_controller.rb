# -*- encoding : utf-8 -*-
class ProjectsController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource

  def index
    @projects = if parent? and !parent.nil?
                  parent.projects
                else
                  Project
                end.accessible_by(current_ability)

    @projects = if params[:query]
                  @projects.by_name("%#{params[:query]}%").order("CHAR_LENGTH(name) ASC")
                else
                  @projects
                end.paginate(:page => params[:project_page])

    @own_projects = current_user.own_projects
    #@part_projects = current_user.projects + current_user.groups.map(&:projects).flatten.uniq - @own_projects
  end

  def new
    @project = Project.new
    @who_owns = :me
  end

  def edit
  end

  def create
    @project = Project.new params[:project]
    @project.owner = choose_owner
    @who_owns = (@project.owner_type == 'User' ? :me : :group)

    if @project.save
      flash[:notice] = t('flash.project.saved') 
      redirect_to @project
    else
      flash[:error] = t('flash.project.save_error')
      flash[:warning] = @project.errors.full_messages.join('. ')
      render :action => :new
    end
  end

  def update
    if @project.update_attributes(params[:project])
      flash[:notice] = t('flash.project.saved')
      redirect_to @project
    else
      @project.save
      flash[:error] = t('flash.project.save_error')
      render :action => :edit
    end
  end

  def destroy
    @project.destroy
    flash[:notice] = t("flash.project.destroyed")
    redirect_to @project.owner
  end

  def fork
    if forked = @project.fork(current_user) and forked.valid?
      redirect_to forked, :notice => t("flash.project.forked")
    else
      flash[:warning] = t("flash.project.fork_error")
      flash[:error] = forked.errors.full_messages
      redirect_to @project
    end
  end

  def sections
    if request.post?
      if @project.update_attributes(params[:project])
        flash[:notice] = t('flash.project.saved')
      else
        @project.save
        flash[:error] = t('flash.project.save_error')
      end
      render :action => :sections
    end
  end

  def remove_user
    @project.relations.by_object(current_user).destroy_all
    flash[:notice] = t("flash.project.user_removed")
    redirect_to projects_path
  end

  protected

  def choose_owner
    if params[:who_owns] == 'group'
      Group.find(params[:owner_id])
    else
      current_user
    end
  end
end
