# -*- encoding : utf-8 -*-
class Projects::CommentsController < Projects::BaseController
  before_filter :authenticate_user!
  load_and_authorize_resource :project
  before_filter :find_commentable
  before_filter :find_or_build_comment
  load_and_authorize_resource :new => :new_line

  include CommentsHelper

  def create
    res = set_additional_data
    if @comment.save
      flash[:notice] = I18n.t("flash.comment.saved")
    else
      flash[:error] = I18n.t("flash.comment.save_error")
      flash[:warning] = @comment.errors.full_messages.join('. ')
    end
    redirect_to project_commentable_path(@project, @commentable) + "#comment#{@comment.id}"
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
    @path = if @commentable.class == Issue
              project_issue_comments_path(@project, @commentable)
            elsif @commentable.class == Grit::Commit
              project_commit_comments_path(@project, @commentable)
            end
    render :layout => false
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

  def set_additional_data
    return true unless params[:path].present? && params[:line].present?
    @comment.data = {:path => params[:path], :line => params[:line]}
    if @commentable.class == Issue && pull = @commentable.pull_request
      repo = Grit::Repo.new(pull.path)
      base_commit = pull.common_ancestor
      head_commit = repo.commits(pull.head_branch).first
      diff = pull.diff repo, base_commit, head_commit
      return false unless diff_path = diff.select {|d| d.a_path == params[:path]}
      comment_line = params[:line].to_i
      return false if comment_line == 0 # NB! also dont want create comment to the diff header

      line_number, line_presence = -1, false
      diff_path[0].diff.each_line do |line|
        line_number = line_number.succ
        # Save 2 lines above and bottom of the diff comment line
        break if line_number > comment_line + 2
        if (comment_line-2..comment_line+2).include? line_number
          @comment.data["line#{line_number-comment_line}"] = line.chomp
          line_presence = true
        end
      end
      return line_presence
    end
  end
end
