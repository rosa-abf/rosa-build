# -*- encoding : utf-8 -*-
class Projects::CommentsController < Projects::BaseController
  before_filter :authenticate_user!
  load_and_authorize_resource :project
  before_filter :find_commentable
  before_filter :find_or_build_comment
  load_and_authorize_resource :new => :new_line

  include CommentsHelper

  def create
    if !set_additional_data
      flash[:error] = I18n.t("flash.comment.save_error")
    elsif @comment.save
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
    return true if params[:path].blank? && params[:line].blank? # not inline comment
    @comment.data = {:path => params[:path], :line => params[:line]}
    if @commentable.class == Issue && pull = @commentable.pull_request
      repo = Grit::Repo.new(pull.path)
      to_commit, from_commit = pull.common_ancestor, repo.commits(pull.head_branch).first

      diff = pull.diff repo, to_commit, from_commit
      diff_path = diff.select {|d| d.a_path == params[:path]}
      return false unless @comment.actual_inline_comment?(diff, true)

      comment_line, line_number, strings = params[:line].to_i, -1, []
      diff_path[0].diff.each_line do |line|
        line_number = line_number.succ
        # Save 2 lines above and bottom of the diff comment line
        break if line_number > comment_line + 2
        if (comment_line-2..comment_line+2).include? line_number
          @comment.data["line#{line_number-comment_line}"] = line.chomp
        end

        # Save lines from the closest header for rendering in the discussion
        if line_number < comment_line - 2
          # Header is the line like "@@ -47,9 +50,8 @@ def initialize(user)"
          if line =~ /^@@ [+-]([0-9]+)(?:,([0-9]+))? [+-]([0-9]+)(?:,([0-9]+))? @@/
            strings = line
          else
            strings << line
          end
        end
      end
      @comment.data[:strings] = strings
      @comment.data[:view_path] = h(diff_path[0].renamed_file ? "#{diff_path[0].a_path.rtruncate 60} -> #{diff_path[0].b_path.rtruncate 60}" : diff_path[0].a_path.rtruncate(120))
      return true
    end
  end
end
