class ActivityFeedObserver < ActiveRecord::Observer
  observe :issue, :comment, :user, :build_list

  def after_create(record)
    case record.class.to_s
    when 'User'
      ActivityFeed.create(
        :user => record,
        :kind => 'new_user_notification',
        :data => {:user_name => record.user_appeal, :user_email => record.email}
      )

    when 'Issue'
      recipients = record.collect_recipient_ids
      recipients.each do |recipient_id|
        recipient = User.find(recipient_id)
        UserMailer.delay.new_issue_notification(record, recipient) if User.find(recipient).notifier.can_notify && User.find(recipient).notifier.new_issue
        ActivityFeed.create(
          :user => recipient,
          :kind => 'new_issue_notification',
          :data => {:user_name => record.creator.name, :user_email => record.creator.email, :user_id => record.creator_id,:issue_serial_id => record.serial_id,
                           :issue_title => record.title, :project_id => record.project.id, :project_name => record.project.name, :project_owner => record.project.owner.uname}
        )
      end

      if record.user_id_changed?
        UserMailer.delay.issue_assign_notification(record, record.user) if record.user.notifier.issue_assign && record.user.notifier.can_notify
        ActivityFeed.create(
          :user => record.user,
          :kind => 'issue_assign_notification',
          :data => {:user_name => record.creator.name, :user_email => record.creator.email, :user_id => record.creator_id, :issue_serial_id => record.serial_id,
                           :project_id => record.project.id, :issue_title => record.title, :project_name => record.project.name, :project_owner => record.project.owner.uname}
        )
      end

    when 'Comment'
      if record.commentable.class == Issue
        subscribes = record.commentable.subscribes
        subscribes.each do |subscribe|
          if record.user_id != subscribe.user_id
            UserMailer.delay.new_comment_notification(record, subscribe.user) if record.can_notify_on_new_comment?(subscribe)
            ActivityFeed.create(
              :user => subscribe.user,
              :kind => 'new_comment_notification',
              :data => {:user_name => record.user.name, :user_email => record.user.email, :user_id => record.user_id, :comment_body => record.body,
                               :issue_title => record.commentable.title, :issue_serial_id => record.commentable.serial_id, :project_id => record.commentable.project.id,
                               :comment_id => record.id, :project_name => record.project.name, :project_owner => record.project.owner.uname}
            )
          end
        end
      elsif record.commit_comment?
        subscribes = Subscribe.comment_subscribes(record).where(:status => true)
        subscribes.each do |subscribe|
          next if record.own_comment?(subscribe.user)
          if subscribe.user.notifier.can_notify and
              ( (subscribe.project.owner?(subscribe.user) && subscribe.user.notifier.new_comment_commit_repo_owner) or
                (subscribe.user.commentor?(record.commentable) && subscribe.user.notifier.new_comment_commit_commentor) or
                (subscribe.user.committer?(record.commentable) && subscribe.user.notifier.new_comment_commit_owner) )
            UserMailer.delay.new_comment_notification(record, subscribe.user)
          end
            ActivityFeed.create(
              :user => subscribe.user,
              :kind => 'new_comment_commit_notification',
              :data => {:user_name => record.user.name, :user_email => record.user.email, :user_id => record.user_id, :comment_body => record.body,
                               :commit_message => record.commentable.message.encode_to_default, :commit_id => record.commentable.id,
                                 :project_id => record.project.id, :comment_id => record.id, :project_name => record.project.name, :project_owner => record.project.owner.uname}
            )
        end
      end

    when 'GitHook'
      change_type = record.change_type
      branch_name = record.refname.match(/\/([\w\d]+)$/)[1]

      last_commits = record.project.git_repository.repo.log(branch_name, nil).first(3)
      first_commiter = User.find_by_email(last_commits[0].author.email) unless last_commits.blank?
      last_commits = last_commits.collect do |commit| #:author => 'author'
        [commit.sha, commit.message]
      end

      if change_type == 'delete'
        kind = 'git_delete_branch_notification'
        options = {:project_id => record.project.id, :project_name => record.project.name, :branch_name => branch_name,
                          :change_type => change_type, :project_owner => record.project.owner.uname}
      else
        kind = 'git_new_push_notification'
        options = {:project_id => record.project.id, :project_name => record.project.name, :last_commits => last_commits, :branch_name => branch_name,
                          :change_type => change_type, :user_email => record.project.git_repository.repo.log(branch_name, nil).first.author.email,
                          :project_owner => record.project.owner.uname}
        options.merge!({:user_id => first_commiter.id, :user_name => first_commiter.name}) if first_commiter
      end

      record.project.owner_and_admin_ids.each do |recipient|
        ActivityFeed.create(
          :user => User.find(recipient),
          :kind => kind,
          :data => options
        )
      end

    when 'Gollum::Committer'
      actor = User.find_by_uname(record.actor.name)
      project_name = record.wiki.path.match(/\/(\w+)\.wiki\.git$/)[1]
      project = Project.find_by_name(project_name)
      commit_sha = record.commit
      #wiki_name = record.wiki.name

      project.owner_and_admin_ids.each do |recipient|
        ActivityFeed.create(
          :user => User.find(recipient),#record.user,
          :kind => 'wiki_new_commit_notification',
          :data => {:user_id => actor.id, :user_name => actor.name, :user_email => actor.email, :project_id => project.id,
                           :project_name => project_name, :commit_sha => commit_sha, :project_owner => project.owner.uname}
        )
      end
    end
  end

  def after_update(record)
    case record.class.to_s
    when 'Issue'
      if record.user_id && record.user_id_changed?
        UserMailer.delay.issue_assign_notification(record, record.user) if record.user.notifier.issue_assign && record.user.notifier.can_notify
        ActivityFeed.create(
          :user => record.user,
          :kind => 'issue_assign_notification',
          :data => {:user_name => record.user.name, :user_email => record.user.email, :issue_serial_id => record.serial_id, :issue_title => record.title,
                           :project_id => record.project.id, :project_name => record.project.name, :project_owner => record.project.owner.uname}
        )
      end

    when 'BuildList'
      if [BuildList::BUILD_PUBLISHED, BuildServer::SUCCESS, BuildServer::BUILD_ERROR, BuildServer::PLATFORM_NOT_FOUND,
           BuildServer::PROJECT_NOT_FOUND, BuildServer::PROJECT_VERSION_NOT_FOUND, BuildList::FAILED_PUBLISH].include? record.status or
         (record.status == BuildList::BUILD_PENDING && record.bs_id_changed?)
        record.project.owner_and_admin_ids.each do |recipient|
          ActivityFeed.create(
            :user => User.find(recipient),
            :kind => 'build_list_notification',
            :data => {:task_num => record.bs_id, :build_list_id => record.id, :status => record.status, :notified_at => record.notified_at,
                             :project_id => record.project_id, :project_name => record.project.name, :project_owner => record.project.owner.uname,
                             :user_name => record.user.name, :user_email => record.user.email, :user_id => record.user_id}
          )
        end
      end
    end
  end

end
