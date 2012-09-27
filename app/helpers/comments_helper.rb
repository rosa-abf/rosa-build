# -*- encoding : utf-8 -*-
module CommentsHelper
  def project_commentable_comment_path(project, commentable, comment)
    case
    when Comment.issue_comment?(commentable.class)
      project_issue_comment_path(project, commentable, comment)
    when Comment.commit_comment?(commentable.class)
      project_commit_comment_path(project, commentable, comment)
    end
  end

  def project_commentable_path(project, commentable)
    case
    when Comment.issue_comment?(commentable.class)
      polymorphic_path [project, commentable.pull_request ? commentable.pull_request : commentable]
    when Comment.commit_comment?(commentable.class)
      commit_path project, commentable.id
    end
  end
end
