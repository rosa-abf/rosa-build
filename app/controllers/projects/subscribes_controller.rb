class Projects::SubscribesController < Projects::BaseController
  before_action :authenticate_user!

  before_action :load_issue

  def create
    authorize @subscribe = @issue.subscribes.build(user_id: current_user.id)
    if @subscribe.save
      flash[:notice] = I18n.t("flash.subscribe.saved")
      redirect_to :back
    else
      flash[:error] = I18n.t("flash.subscribe.saved_error")
      redirect_to :back
    end
  end

  def destroy
    authorize @subscribe = @issue.subscribes.find_by(user_id: current_user.id)
    @subscribe.destroy

    flash[:notice] = t("flash.subscribe.destroyed")
    redirect_to :back
  end

  private

  # Private: before_action hook which loads Issue.
  def load_issue
    authorize @issue = @project.issues.find_by!(serial_id: params[:issue_id]), :show?
  end
end
