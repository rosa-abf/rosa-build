class Projects::CommitSubscribesController < Projects::BaseController
  before_action :authenticate_user!
  before_action :find_commit

  def create
    authorize @commit.subscribes.build(user_id: current_user.id)
    if Subscribe.subscribe_to_commit(@options)
      flash[:notice] = I18n.t("flash.subscribe.commit.saved")
      # TODO js
      redirect_to commit_path(@project, @commit)
    else
      flash[:error] = I18n.t("flash.subscribe.saved_error")
      redirect_to commit_path(@project, @commit)
    end
  end

  def destroy
    authorize @commit.subscribes.build(user_id: current_user.id)
    Subscribe.unsubscribe_from_commit(@options)
    flash[:notice] = t("flash.subscribe.commit.destroyed")
    redirect_to commit_path(@project, @commit)
  end

  protected

  def find_commit
    @commit = @project.repo.commit(params[:commit_id])
    @options = {project_id: @project.id, subscribeable_id: @commit.id.hex, subscribeable_type: @commit.class.name, user_id: current_user.id}
  end
end
