# -*- encoding : utf-8 -*-
module PullRequestHelper
  def merge_activity comments, commits
    common_comments, pull_comments = comments.partition {|c| c.data.blank?}
    common_comments = common_comments.map{ |c| [c.created_at, c] }
    pull_comments = pull_comments.group_by(&:data).map{|data, c| [c.first.created_at, [data || {}, [c].flatten]]}
    commits = commits.map{ |c| [(c.committed_date || c.authored_date), c] }
    (common_comments + pull_comments + commits).sort_by{ |c| c[0] }.map{ |c| c[1] }
  end

  def pull_status_label pull
    statuses = {'ready' => 'success', 'closed' => 'important', 'merged' => 'important', 'blocked' => 'warning'}
    content_tag :span, t("projects.pull_requests.statuses.#{pull.status}"), :class => "label-bootstrap label-#{statuses[pull.status]}"
  end

  def pull_status pull
    if %w(blocked merged closed ready open).include? pull.status
      t("projects.pull_requests.#{pull.status}", :user => pull.issue.closer.try(:uname), :to_ref => show_ref(pull, 'to'),
        :from_ref => show_ref(pull, 'from'), :time => pull.issue.closed_at).html_safe
    else
        raise "pull id (#{pull.id}) wrong status #{pull.status} "
    end
  end

  def pull_header pull
    str = "#{t '.header'} #{t 'from'} <span class='label-bootstrap label-info font14'> \
   #{show_ref pull, 'from'}</span> \
   #{t 'into'} <span class='label-bootstrap label-info font14'> \
   #{show_ref pull, 'to'}</span>"
    str << " #{t 'by'} #{link_to pull.user.uname, user_path(pull.user)}" if pull.user# pull.persisted?
    str.html_safe
  end

  #helper for helpers
  def show_ref pull, which, limit = 30
    project, ref = pull.send("#{which}_project"), pull.send("#{which}_ref")
    fullname = if which == 'into'
                 "#{project.owner.uname.truncate limit}/#{project.name.truncate limit}"
               elsif which == 'from'
                 "#{pull.from_project_owner_uname.truncate limit}/#{pull.from_project_name.truncate limit}"
               end
    link_to "#{fullname}: #{ref.truncate limit}", ref_path(project, ref)
  end

  def ref_path project, ref
    if project && project.repo.branches_and_tags.map(&:name).include?(ref)
      tree_path(project, ref)
    else
      '#'
    end
  end

  def ref_selector_options(project, current)
    res = []
    value = Proc.new {|t| [t.name.truncate(40)]}
    res << [I18n.t('layout.git.repositories.branches'), project.repo.branches.map(&value)]
    res << [I18n.t('layout.git.repositories.tags'), project.repo.tags.map(&value)]

    grouped_options_for_select(res, current)
  end
end
