# -*- encoding : utf-8 -*-
class Projects::HooksController < Projects::BaseController
  before_filter :authenticate_user!
  load_resource :project

  # GET /../hooks
  # GET /../hooks.json
  def index
    @name = params[:name]
    @hooks = @project.hooks.for_name(@name).order('name asc, created_at asc')
    if @name.present?
      render :show
    else
      render :index
    end
  end

  # GET /../hooks/new
  # GET /../hooks/new.json
  def new
    @hook = @project.hooks.new(params[:hook])
  end

  # GET /../hooks/1/edit
  def edit
    @hook = @project.hooks.find params[:id]
  end

  # POST /../hooks
  # POST /../hooks.json
  def create
    @hook = @project.hooks.new params[:hook]
    if @hook.save
      redirect_to project_hooks_path(@project, :name => @hook.name), :notice => 'Hook was successfully created.'
    else
      flash[:error] = t('flash.hook.save_error')
      flash[:warning] = @hook.errors.full_messages.join('. ')
      render :new
    end
  end

  # PUT /../hooks/1
  # PUT /../hooks/1.json
  def update
    @hook = @project.hooks.find params[:id]
    if @hook.update_attributes(params[:hook])
      redirect_to project_hooks_path(@project, :name => @hook.name), :notice => 'Hook was successfully updated.'
    else
      flash[:error] = t('flash.hook.save_error')
      flash[:warning] = @hook.errors.full_messages.join('. ')
      render :edit
    end
  end

  # DELETE /../hooks/1
  # DELETE /../hooks/1.json
  def destroy
    @hook = @project.hooks.find params[:id]
    @hook.destroy

    respond_to do |format|
      format.html { redirect_to hooks_url }
      format.json { head :no_content }
    end
  end
end
