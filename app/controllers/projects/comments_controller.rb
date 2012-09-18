# -*- encoding : utf-8 -*-
class Projects::CommentsController < Projects::BaseController
  before_filter :authenticate_user!
  load_and_authorize_resource :project
  before_filter :find_commentable
  before_filter :find_or_build_comment
  load_and_authorize_resource #:through => :commentable

  include CommentsHelper

  def create
    if @comment.save
      flash[:notice] = I18n.t("flash.comment.saved")
      redirect_to project_commentable_path(@project, @commentable)
    else
      flash[:error] = I18n.t("flash.comment.save_error")
      render :action => 'new'
    end
  end

  def edit
  end

  def update
    status = @comment.update_attributes(params[:comment]) ? 200 : 500
    render :inline => view_context.markdown(@comment.body), :status => status
  end

  def destroy
    @comment.destroy
    flash[:notice] = t("flash.comment.destroyed")
    redirect_to project_commentable_path(@project, @commentable)
  end

  protected

  def find_commentable
    @commentable = params[:issue_id].present? && @project.issues.find_by_serial_id(params[:issue_id]) ||
                   params[:commit_id].present? && @project.repo.commit(params[:commit_id])
  end

  def find_or_build_comment
    @comment = params[:id].present? && Comment.find(params[:id]) ||
               current_user.comments.build(params[:comment]) {|c| c.commentable = @commentable; c.project = @project}
  end
end
