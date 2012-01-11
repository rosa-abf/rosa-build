class CommentsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :set_commentable, :only => [:index, :edit, :create]
  before_filter :find_project, :only => [:index, :edit]
  before_filter :find_comment, :only => [:edit, :update, :destroy]

  authorize_resource :only => [:show, :edit, :update, :destroy]
  authorize_resource :project, :only => [:index]

  def index
    @comments = @commentable.comments
  end

  def create
    @comment = @commentable.comments.build(params[:comment])
    @comment.user = current_user
    if @comment.save
      flash[:notice] = I18n.t("flash.comment.saved")
      redirect_to [@commentable.project, @commentable]
    else
      flash[:error] = I18n.t("flash.comment.save_error")
      render :action => 'new'
    end
  end

  def edit
    if @commentable
      @issue = @commentable
      @update_url = project_issue_comment_path(@project, @issue.id, @comment)
    end
    if @comment.commentable_type == 'Commit'
      @commit = @project.git_repository.commit(@comment.commentable_id)
      @update_url = project_commit_comment_path(@project, @commit, @comment)
    end
  end

  def update
    if @comment.update_attributes(params[:comment])
      flash[:notice] = I18n.t("flash.comment.saved")
      #redirect_to :back
      redirect_to [@comment.commentable.project, @comment.commentable]
    else
      flash[:error] = I18n.t("flash.comment.save_error")
      render :action => 'new'
    end
  end

  def destroy
    @comment.destroy

    flash[:notice] = t("flash.comment.destroyed")
    redirect_to :back
  end

  private

  def find_commentable
    #params.each do |name, value|
    #  if name =~ /(.+)_id$/
    #    return $1.classify.constantize.find(value)
    #  end
    #end
    #nil
    return nil if params[:issue_id].nil?
    Issue.find(params[:issue_id])
  end

  def set_commentable
    @commentable = find_commentable
  end

  def find_comment
    @comment = Comment.find(params[:id])
  end

  def find_project
    @project = Project.find(params[:project_id])
  end
end
