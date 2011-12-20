class CommentsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :set_commentable, :only => [:index, :edit, :create]

  def index
    @comments = @commentable.comments
  end

  def create
    @comment = @commentable.comments.build(params[:comment])
    @comment.user = current_user
    if @comment.save
      flash[:notice] = I18n.t("flash.comment.saved")
      redirect_to :back
    else
      flash[:error] = I18n.t("flash.comment.saved_error")
      render :action => 'new'
    end
  end

  def edit
    @comment = Comment.find(params[:id])
    @issue = @commentable
    @project = @issue.project
  end

  def update
    @comment = Comment.find(params[:id])
    if @comment.update_attributes(params[:comment])
      flash[:notice] = I18n.t("flash.comment.saved")
      redirect_to :back
    else
      flash[:error] = I18n.t("flash.comment.saved_error")
      render :action => 'new'
    end
  end

  def destroy
    @comment = Comment.find(params[:id])
    @comment.destroy

    flash[:notice] = t("flash.comment.destroyed")
    redirect_to :back
  end

  private

  def find_commentable
    params.each do |name, value|
      if name =~ /(.+)_id$/
        return $1.classify.constantize.find(value)
      end
    end
    nil
  end

  def set_commentable
    @commentable = find_commentable
  end
end
