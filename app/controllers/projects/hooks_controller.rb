# -*- encoding : utf-8 -*-
class Projects::HooksController < Projects::BaseController
  before_filter :authenticate_user!
  load_and_authorize_resource :project
  load_and_authorize_resource :hook
  skip_load_and_authorize_resource :hook, :only => [:index, :new, :create]
  before_filter lambda { authorize! :edit, @project }, :only => [:index, :new, :create]


  # GET /uname/project/hooks
  # GET /uname/project/hooks?name=web
  def index
    @name = params[:name]
    @hooks = @project.hooks.for_name(@name).order('name asc, created_at desc')
    if @name.present?
      render :show
    else
      render :index
    end
  end

  # GET /uname/project/hooks/new
  def new
    @hook = @project.hooks.new(params[:hook])
  end

  # GET /uname/project/hooks/1/edit
  def edit
    @hook = @project.hooks.find params[:id]
  end

  # POST /uname/project/hooks
  def create
    @hook = @project.hooks.new params[:hook]
    if @hook.save
      redirect_to project_hooks_path(@project, :name => @hook.name), :notice => t('flash.hook.created')
    else
      flash[:error] = t('flash.hook.save_error')
      flash[:warning] = @hook.errors.full_messages.join('. ')
      render :new
    end
  end

  # PUT /uname/project/hooks/1
  def update
    @hook = @project.hooks.find params[:id]
    if @hook.update_attributes(params[:hook])
      redirect_to project_hooks_path(@project, :name => @hook.name), :notice => t('flash.hook.updated')
    else
      flash[:error] = t('flash.hook.save_error')
      flash[:warning] = @hook.errors.full_messages.join('. ')
      render :edit
    end
  end

  # DELETE /uname/project/hooks/1
  def destroy
    @hook = @project.hooks.find params[:id]
    @hook.destroy
    redirect_to project_hooks_path(@project, :name => @hook.name)
  end

end
