# -*- encoding : utf-8 -*-
module PullRequestHelper
  def pull_status_label pull
    label = case pull.status
                when 'ready'
                  'success'
                when 'closed', 'merged'
                  'important'
                when 'blocked'
                  'warning'
                end
    "<span class='label-bootstrap label-#{label}'>#{t "projects.pull_requests.statuses.#{pull.status}"}</span>".html_safe
  end

  def pull_status pull
    if %w(blocked merged closed ready).include? pull.status
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
    name = "#{project.owner.uname.truncate limit}: #{ref.truncate limit}"
    link_to name, ref_path(project, ref)

  end

  def ref_path project, ref
    return tree_path(project, ref) if project.branches_and_tags.include? ref
    return commit_path(project, ref) if project.git_repository.commit ref
    '#'
  end
end
