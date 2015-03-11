class Projects::CommentsController < Projects::BaseController
  before_action :authenticate_user!
  load_and_authorize_resource :project
  before_action :find_commentable
  before_action :find_or_build_comment
  load_and_authorize_resource new: :new_line

  include CommentsHelper

  def create
    respond_to do |format|
      if !@comment.set_additional_data params
        format.json {
                      render json: {
                                     error:   I18n.t("flash.comment.save_error"),
                                     message: @comment.errors.full_messages
                                   }
                    }
      elsif @comment.save
        format.json {}
      else
        format.json { render json: { error: I18n.t("flash.comment.save_error") }, status: 422 }
      end
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
