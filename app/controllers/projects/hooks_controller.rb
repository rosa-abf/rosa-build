# -*- encoding : utf-8 -*-
class Projects::HooksController < Projects::BaseController
  before_filter :authenticate_user!
  load_resource :project

  # GET /../hooks
  # GET /../hooks.json
  def index
    @hooks = @project.hooks.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @hooks }
    end
  end

  # GET /../hooks/1
  # GET /../hooks/1.json
  def show
    @hook = @project.hooks.find params[:id]

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @hook }
    end
  end

  # GET /../hooks/new
  # GET /../hooks/new.json
  def new
    @hook = @project.hooks.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @hook }
    end
  end

  # GET /../hooks/1/edit
  def edit
    @hook = @project.hooks.find params[:id]
  end

  # POST /../hooks
  # POST /../hooks.json
  def create
    @hook = @project.hooks.new params[:hook]

    respond_to do |format|
      if @hook.save
        format.html { redirect_to @hook, notice: 'Hook was successfully created.' }
        format.json { render json: @hook, status: :created, location: @hook }
      else
        format.html { render action: "new" }
        format.json { render json: @hook.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /../hooks/1
  # PUT /../hooks/1.json
  def update
    @hook = @project.hooks.find params[:id]

    respond_to do |format|
      if @hook.update_attributes(params[:hook])
        format.html { redirect_to @hook, notice: 'Hook was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @hook.errors, status: :unprocessable_entity }
      end
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
