# -*- encoding : utf-8 -*-
module PullRequestHelper
  def merge_activity comments, commits
    issue_comments = @issue.comments.map{ |c| [c.created_at, c] }
    commits = @commits.map{ |c| [(c.committed_date || c.authored_date), c] }
    (issue_comments + commits).sort_by{ |c| c[0] }.map{ |c| c[1] }
  end

  def pull_status_label pull
    statuses = {'ready' => 'success', 'closed' => 'important', 'merged' => 'important', 'blocked' => 'warning'}
    content_tag :span, t("projects.pull_requests.statuses.#{pull.status}"), :class => "label-bootstrap label-#{statuses[pull.status]}"
  end

  def pull_status pull
    if %w(blocked merged closed ready open).include? pull.status
      t("projects.pull_requests.#{pull.status}", :user => pull.issue.closer.try(:uname), :base_ref => show_ref(pull, 'base'),
        :head_ref => show_ref(pull, 'head'), :time => pull.issue.closed_at).html_safe
    else
        raise "pull id (#{pull.id}) wrong status #{pull.status} "
    end
  end

  def pull_header pull
    str = "#{t '.header'} #{t 'into'} <span class='label-bootstrap label-info font14'> \
   #{show_ref pull, 'base'}</span> \
   #{t 'from'} <span class='label-bootstrap label-info font14'> \
   #{show_ref pull, 'head'}</span>"
    str << " #{t 'by'} #{link_to pull.user.uname, user_path(pull.user)}" if pull.persisted?
    str.html_safe
  end

  #helper for helpers
  def show_ref pull, which, limit = 30
    project, ref = pull.send("#{which}_project"), pull.send("#{which}_ref")
    link_to "#{project.owner.uname.truncate limit}/#{project.name.truncate limit}: #{ref.truncate limit}", ref_path(project, ref)
  end

  def ref_path project, ref
    return tree_path(project, ref) if project.repo.branches_and_tags.map(&:name).include? ref
    return commit_path(project, ref) if project.repo.commit ref
    '#'
  end
end
