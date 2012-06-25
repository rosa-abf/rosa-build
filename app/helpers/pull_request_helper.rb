# -*- encoding : utf-8 -*-
module PullRequestHelper
  def pull_status pull
    if %w(blocked merged closed).include? pull.status
      t "projects.pull_requests.#{pull.status}", :user => pull.issue.closer.try(:uname), :base_ref => pull.base_ref, :head_ref => pull.head_ref,
        :time => pull.issue.closed_at
    else
        raise "pull id (#{pull.id}) wrong status #{pull.status} "
    end
  end
end