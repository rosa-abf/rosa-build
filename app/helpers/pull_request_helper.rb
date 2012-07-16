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
      t "projects.pull_requests.#{pull.status}", :user => pull.issue.closer.try(:uname), :base_ref => pull.base_ref, :head_ref => pull.head_ref,
        :time => pull.issue.closed_at
    else
        raise "pull id (#{pull.id}) wrong status #{pull.status} "
    end
  end

  def pull_header pull
    str = "#{t '.header'} #{t 'into'} <span class='label-bootstrap label-info font14'> \
   #{pull.base_project.owner.uname.truncate 30}: #{pull.base_ref.truncate 30}</span> \
   #{t 'from'} <span class='label-bootstrap label-info font14'> \
   #{pull.base_project.owner.uname.truncate 30}: #{pull.head_ref.truncate 30}</span>"
    str << " #{t 'by'} #{link_to pull.user.uname, user_path(pull.user)}" if pull.persisted?
    str.html_safe
  end
end