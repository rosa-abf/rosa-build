class Projects::CommentsController < Projects::BaseController
  before_filter :authenticate_user!
  load_and_authorize_resource :project
  before_filter :find_commentable
  before_filter :find_or_build_comment
  load_and_authorize_resource :new => :new_line

  include CommentsHelper

  def create
    anchor = ''
    if !@comment.set_additional_data params
      flash[:error] = I18n.t("flash.comment.save_error")
    elsif @comment.save
      flash[:notice] = I18n.t("flash.comment.saved")
      anchor = view_context.comment_anchor(@comment)
    else
      flash[:error] = I18n.t("flash.comment.save_error")
      flash[:warning] = @comment.errors.full_messages.join('. ')
    end
    redirect_to "#{project_commentable_path(@project, @commentable)}##{anchor}"
  end

  def edit
  end

  def update
    status, message = if @comment.update_attributes(params[:comment])
      [200, view_context.markdown(@comment.body)]
    else
      [400, view_context.local_alert(@comment.errors.full_messages.join('. '))]
    end
    render :inline => message, :status => status
  end

  def destroy
    @comment.destroy
    flash[:notice] = t("flash.comment.destroyed")
    redirect_to project_commentable_path(@project, @commentable)
  end

  def new_line
    @path = view_context.project_commentable_comments_path(@project, @commentable)
    render :layout => false
  end

  protected

  def find_commentable
    @commentable = params[:issue_id].present? && @project.issues.find_by_serial_id(params[:issue_id]) ||
                   params[:commit_id].present? && @project.repo.commit(params[:commit_id])
  end

  def find_or_build_comment
    @comment = params[:id].present? && Comment.where(:automatic => false).find(params[:id]) ||
               current_user.comments.build(params[:comment]) {|c| c.commentable = @commentable; c.project = @project}
  end
end
