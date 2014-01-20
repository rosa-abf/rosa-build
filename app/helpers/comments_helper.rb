module CommentsHelper
  def project_commentable_comment_path(project, commentable, comment)
    if Comment.issue_comment?(commentable.class)
      project_issue_comment_path(project, commentable, comment)
    elsif Comment.commit_comment?(commentable.class)
      project_commit_comment_path(project, commentable, comment)
    end
  end

  def project_commentable_path(project, commentable)
    if Comment.issue_comment?(commentable.class)
      polymorphic_path [project, commentable.pull_request ? commentable.pull_request : commentable]
    elsif Comment.commit_comment?(commentable.class)
      commit_path project, commentable.id
    end
  end

  def project_commentable_comments_path(project, commentable)
    if commentable.is_a? Issue
      project_issue_comments_path(@project, @commentable)
    elsif commentable.is_a? Grit::Commit
      project_commit_comments_path(@project, @commentable)
    end
  end

  def comment_anchor c
    "#{(c.data.present? && c.actual_inline_comment?) ? 'diff-' : ''}comment#{c.id}"
  end
end
