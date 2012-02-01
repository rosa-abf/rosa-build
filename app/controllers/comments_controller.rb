# -*- encoding : utf-8 -*-
class CommentsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :set_commentable, :only => [:index, :edit, :create, :update, :destroy]
  #before_filter :find_project, :only => [:index, :edit]
  before_filter :find_comment, :only => [:edit, :update, :destroy]

  authorize_resource :only => [:show, :edit, :update, :destroy]
  authorize_resource :project, :only => [:index]

  def index
    @comments = @commentable.comments
  end

  def create
    @comment = @commentable.comments.build(params[:comment]) if @commentable.class == Issue
    @comment = Comment.new(params[:comment].merge(:commentable_id => @commentable.id, :commentable_type => @commentable.class.name, :project => @project)) if @commentable.class == Grit::Commit
    @comment.user = current_user
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

  def find_commentable
    #params.each do |name, value|
    #  if name =~ /(.+)_id$/
    #    return $1.classify.constantize.find(value)
    #  end
    #end
    #nil
    if params[:issue_id].present?
      return Issue.find_by_serial_id_and_project_id(params[:issue_id], params[:project_id])
    elsif params[:commit_id].present?
      return @project.git_repository.commit(params[:commit_id])
    end
  end

  def set_commentable
    find_project
    @commentable = find_commentable
  end

  def find_comment
    @comment = Comment.find(params[:id])
    if @comment.commentable_type == 'Grit::Commit'
      @comment.project = @project
      @comment.helper
    end
  end

  def find_project
    @project = Project.find(params[:project_id])
  end

  protected

  def commentable_path
    @commentable.class == Issue ? [@project, @commentable] : commit_path(@project, @commentable.id)
  end

end
