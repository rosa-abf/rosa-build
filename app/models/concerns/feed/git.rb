module Feed::Git

  def self.create_notifications(record)

    case record.class.to_s
    when 'GitHook'
      return unless record.project
      PullRequest.where("from_project_id = ? OR to_project_id = ?", record.project, record.project).needed_checking.each {|pull| pull.check}
      record.project.hooks.each{ |h| h.receive_push(record) }

      change_type = record.change_type
      branch_name = record.refname.split('/').last

      if change_type == 'delete'
        kind = 'git_delete_branch_notification'
        options = {project_id: record.project.id, project_name: record.project.name, branch_name: branch_name,
                   change_type: change_type, project_owner: record.project.owner.uname}
      else
        if record.message # online update
          last_commits, commits = [[record.newrev, record.message]], []
          all_commits = last_commits
        else
          commits       = record.project.repo.commits_between(record.oldrev, record.newrev)
          all_commits   = commits.collect { |commit| [commit.sha, commit.message] }
          last_commits  = all_commits.last(3).reverse
        end

        kind = 'git_new_push_notification'
        options = {project_id: record.project.id, project_name: record.project.name, last_commits: last_commits,
                   branch_name: branch_name, change_type: change_type, project_owner: record.project.owner.uname}
        if commits.count > 3
          commits = commits[0...-3]
          options.merge!({other_commits_count: commits.count, other_commits: "#{commits[0].sha[0..9]}...#{commits[-1].sha[0..9]}"})
        end

        if all_commits.count > 0
          Statistic.statsd_increment(
            activity_at:  Time.now,
            key:          Statistic::KEY_COMMIT,
            project_id:   record.project.id,
            user_id:      record.user.id,
            counter:      all_commits.count
          )
          Comment.create_link_on_issues_from_item(record, all_commits)
        end
      end
      options.merge!({user_id: record.user.id, user_name: record.user.name, user_email: record.user.email}) if record.user

      record.project.admins.each do |recipient|
        next if record.user && record.user.id == recipient.id
        ActivityFeed.create!(
          user: recipient,
          kind: kind,
          data: options
        )
        if recipient.notifier.can_notify && recipient.notifier.update_code
          UserMailer.send(kind, recipient, options).deliver
        end
      end

    when 'Hash' # 'Gollum::Committer'
      actor = User.find_by! uname: record[:actor_name]
      project = Project.find record[:project_id]

      project.admins.each do |recipient|
        ActivityFeed.create!(
          user: recipient,
          kind: 'wiki_new_commit_notification',
          data: {user_id: actor.id, user_name: actor.name, user_email: actor.email, project_id: project.id,
                 project_name: project.name, commit_sha: record[:commit_sha], project_owner: project.owner.uname}
        )
      end
    end
  end
end
