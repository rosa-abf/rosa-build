# -*- encoding : utf-8 -*-
class CommentsController < ApplicationController
  before_filter :authenticate_user!

  load_resource :project
  before_filter :set_commentable
  before_filter :find_comment, :only => [:edit, :update, :destroy]
  authorize_resource

  def index
    @comments = @commentable.comments
  end

  def create
    @comment = @commentable.comments.build(params[:comment]) if @commentable.class == Issue
    if @commentable.class == Grit::Commit
      @comment = Comment.new(params[:comment].merge(:commentable_id => @commentable.id.hex, :commentable_type => @commentable.class.name))
    end
    @comment.project = @project
    @comment.user_id = current_user.id
    if @comment.save
      flash[:notice] = I18n.t("flash.comment.saved")
      redirect_to commentable_path
    else
      flash[:error] = I18n.t("flash.comment.save_error")
      render :action => 'new'
    end
  end

  def edit
    @update_url = case @commentable.class.name
                  when "Issue"
                    project_issue_comment_path(@project, @commentable, @comment)
                  when "Grit::Commit"
                    project_commit_comment_path(@project, @commentable, @comment)
                  end
    @commentable_path = commentable_path
  end

  def update
    if @comment.update_attributes(params[:comment])
      flash[:notice] = I18n.t("flash.comment.saved")
      redirect_to commentable_path
    else
      flash[:error] = I18n.t("flash.comment.save_error")
      render :action => 'new'
    end
  end

  def destroy
    @comment.destroy

    flash[:notice] = t("flash.comment.destroyed")
    redirect_to commentable_path
  end

  private

  def set_commentable
    @commentable = if params[:issue_id].present?
                                  @project.issues.find_by_serial_id params[:issue_id]
                                elsif params[:commit_id].present?
                                  @project.git_repository.commit params[:commit_id]
                                end
  end

  def find_comment
    @comment = Comment.find(params[:id])
    if @comment.commit_comment?
      @comment.project = @project
      @comment.helper
    end
  end

  def commentable_path
    @commentable.class == Issue ? [@project, @commentable] : commit_path(@project, @commentable.id)
  end

end
