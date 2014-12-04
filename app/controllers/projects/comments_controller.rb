class Projects::CommentsController < Projects::BaseController
  before_filter :authenticate_user!
  load_and_authorize_resource :project
  before_filter :find_commentable
  before_filter :find_or_build_comment
  load_and_authorize_resource new: :new_line

  include CommentsHelper

  def create
    if !@comment.set_additional_data params
      render online: I18n.t("flash.comment.save_error"), layout: false
    elsif @comment.save
      locals = {
        comment: @comment,
        data: { project: @project, commentable: @commentable }
      }
      render partial: 'projects/comments/comment', locals: locals, layout: false
    else
      render online: I18n.t("flash.comment.save_error"), layout: false
    end
  end

  def edit
  end

  def update
    status, message = if @comment.update_attributes(params[:comment])
      [200, view_context.markdown(@comment.body)]
    else
      [422, 'error']
    end
    render json: {body: message}, status: status
  end

  def destroy
    @comment.destroy
    render json: nil
  end

  def new_line
    @path = view_context.project_commentable_comments_path(@project, @commentable)
    render layout: false
  end

  protected

  def find_commentable
    @commentable = params[:issue_id].present? && @project.issues.find_by(serial_id: params[:issue_id]) ||
                   params[:commit_id].present? && @project.repo.commit(params[:commit_id])
  end

  def find_or_build_comment
    @comment = params[:id].present? && Comment.where(automatic: false).find(params[:id]) ||
               current_user.comments.build(params[:comment]) {|c| c.commentable = @commentable; c.project = @project}
  end
end
