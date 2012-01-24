class CommitSubscribesController < ApplicationController
  before_filter :authenticate_user!

  load_and_authorize_resource :project

  before_filter :find_commit

  def create
    if Subscribe.set_subscribe(@project, @commit, current_user.id, Subscribe::ON)
      flash[:notice] = I18n.t("flash.subscribe.commit.saved")
      # TODO js
      redirect_to commit_path(@project, @commit)
    else
      flash[:error] = I18n.t("flash.subscribe.saved_error")
      redirect_to commit_path(@project, @commit)
    end
  end

  def destroy
    Subscribe.set_subscribe(@project, @commit, current_user.id, Subscribe::OFF)
    flash[:notice] = t("flash.subscribe.commit.destroyed")
    redirect_to commit_path(@project, @commit)
  end

  protected

  def find_commit
    @commit = @project.git_repository.commit(params[:commit_id])
  end
end
