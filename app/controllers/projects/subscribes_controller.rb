class Projects::SubscribesController < Projects::BaseController
  before_filter :authenticate_user!

  load_and_authorize_resource :project
  load_and_authorize_resource :issue, :through => :project, :find_by => :serial_id
  load_and_authorize_resource :subscribe, :through => :issue, :find_by => :user_id

  def create
    @subscribe = @issue.subscribes.build(:user_id => current_user.id)
    if @subscribe.save
      flash[:notice] = I18n.t("flash.subscribe.saved")
      redirect_to :back
    else
      flash[:error] = I18n.t("flash.subscribe.saved_error")
      redirect_to :back
    end
  end

  def destroy
    @subscribe.destroy

    flash[:notice] = t("flash.subscribe.destroyed")
    redirect_to :back
  end
end
