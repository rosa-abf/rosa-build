class CommentsController < ApplicationController
  before_filter :authenticate_user!

  def index
    @commentable = find_commentable
    @comments = @commentable.comments
  end

  def create
    @commentable = find_commentable
    @comment = @commentable.comments.build(params[:comment])
    if @comment.save
      flash[:notice] = I18n.t("flash.comment.saved")
      redirect_to :id => nil
    else
      flash[:error] = I18n.t("flash.comment.saved_error")
      render :action => 'new'
    end
  end

  def update
    @comment = Comment.find(params[:id])
    if @comment.update_attributes(params[:comment])
      flash[:notice] = I18n.t("flash.comment.saved")
      redirect_to :id => nil
    else
      flash[:error] = I18n.t("flash.comment.saved_error")
      render :action => 'new'
    end
  end

  def destroy
    @comment = Comment.find(params[:id])
    @comment.destroy

    flash[:notice] = t("flash.comment.destroyed")
    redirect_to root_path
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
end
