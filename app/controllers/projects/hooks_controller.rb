class Projects::HooksController < Projects::BaseController
  before_action :authenticate_user!
  before_action -> { authorize @project, :update? }
  before_action :load_hook, except: %i(index new create)

  def index
    @name = params[:name]
    @hooks = @project.hooks.for_name(@name).order('name asc, created_at desc')
    render(:show) if @name.present?
  end

  def new
    @hook = @project.hooks.build
  end

  def edit
  end

  def create
    authorize @hook = @project.hooks.build(hook_params)
    if @hook.save
      redirect_to project_hooks_path(@project, name: @hook.name), notice: t('flash.hook.created')
    else
      flash[:error] = t('flash.hook.save_error')
      flash[:warning] = @hook.errors.full_messages.join('. ')
      render :new
    end
  end

  def update
    if @hook.update_attributes(hook_params)
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

  private

  def hook_params
    subject_params(Hook)
  end

  # Private: before_action hook which loads Hook.
  def load_hook
    authorize @hook = @project.hooks.find(params[:id])
  end

end
