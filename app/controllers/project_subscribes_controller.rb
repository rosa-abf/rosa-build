class ProjectSubscribesController < ApplicationController
  before_filter :authenticate_user!

  load_and_authorize_resource :project
  load_resource :subscribe
  #load_and_authorize_resource :subscribe, :find_by => :user_id

  def create
    @subscribe = @project.commit_comments_subscribes.build(:user_id => current_user.id)
    if @subscribe.save
      flash[:notice] = I18n.t("flash.subscribe.saved")
      redirect_to @project
    else
      flash[:error] = I18n.t("flash.subscribe.saved_error")
      redirect_to @project
    end
  end

  def destroy
    @project.commit_comments_subscribes.where(:user_id => current_user.id).first.destroy # FIXME
    flash[:notice] = t("flash.subscribe.destroyed")
    redirect_to @project
  end
end
