class Projects::HooksController < Projects::BaseController
  before_action :authenticate_user!
  load_and_authorize_resource :project
  load_and_authorize_resource :hook, through: :project

  def index
    authorize! :edit, @project
    @name = params[:name]
    @hooks = @project.hooks.for_name(@name).order('name asc, created_at desc')
    render(:show) if @name.present?
  end

  def new
  end

  def edit
  end

  def create
    if @hook.save
      redirect_to project_hooks_path(@project, name: @hook.name), notice: t('flash.hook.created')
    else
      flash[:error] = t('flash.hook.save_error')
      flash[:warning] = @hook.errors.full_messages.join('. ')
      render :new
    end
  end

  def update
    if @hook.update_attributes(params[:hook])
      redirect_to project_hooks_path(@project, name: @hook.name), notice: t('flash.hook.updated')
    else
      flash[:error] = t('flash.hook.save_error')
      flash[:warning] = @hook.errors.full_messages.join('. ')
      render :edit
    end
  end

  def destroy
    @hook.destroy
    redirect_to project_hooks_path(@project, name: @hook.name)
  end

end
