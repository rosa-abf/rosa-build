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
        options = {project_id: record.project.id, branch_name: branch_name, change_type: change_type}
      else
        if record.message # online update
          last_commits, commits = [[record.newrev, record.message.truncate(70, omission: '…')]], []
          all_commits = last_commits
        else
          commits       = record.project.repo.commits_between(record.oldrev, record.newrev)
          all_commits   = commits.collect { |commit| [commit.sha, commit.message.truncate(70, omission: '…')] }
          last_commits  = all_commits.last(3).reverse
        end

        kind = 'git_new_push_notification'
        options = {project_id: record.project.id, last_commits: last_commits,
                   branch_name: branch_name, change_type: change_type}
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
      options.merge!({creator_name: record.user.name, creator_email: record.user.email}) if record.user

      options_for_mail = options.merge(project_owner: record.project.owner_uname,
                                       project_name:  record.project.name)
      record.project.all_members.each do |recipient|
        ActivityFeed.create!(
          user:          recipient,
          kind:          kind,
          project_owner: record.project.owner_uname,
          project_name:  record.project.name,
          creator_id:    record.user.id,
          data:          options
        )
        next if record.user && record.user.id == recipient.id
        if recipient.notifier.can_notify && recipient.notifier.update_code
          UserMailer.send(kind, recipient, options_for_mail).deliver
        end
      end

    when 'Hash' # 'Gollum::Committer'
      actor = User.find_by! uname: record[:actor_name]
      project = Project.find record[:project_id]

      project.all_members.each do |recipient|
        ActivityFeed.create!(
          user: recipient,
          kind: 'wiki_new_commit_notification',
          project_owner: project.owner_uname,
          project_name:  project.name,
          creator_id:    actor.id,
          data: {creator_name: actor.name, creator_email: actor.email,
                 project_id: project.id, commit_sha: record[:commit_sha]}
        )
      end
    end
  end
end
