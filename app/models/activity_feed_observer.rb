class ActivityFeedObserver < ActiveRecord::Observer
  observe :issue, :comment, :user

  def after_create(record)
    case record.class.to_s
    when 'User'
      ActivityFeed.create(
        :user => record,
        :kind => 'new_user_notification',
        :date => {:user_name => record.name, :user_email => record.email, :password => user.password}
      )

    when 'Issue'
      recipients = record.collect_recipient_ids
      recipients.each do |recipient_id|
        recipient = User.find(recipient_id)
        UserMailer.delay.new_issue_notification(record, recipient) if User.find(recipient).notifier.can_notify && User.find(recipient).notifier.new_issue
        ActivityFeed.create(
          :user => recipient,
          :kind => 'new_issue_notification',
          :data => {:user_name => recipient.name, :issue_serial_id => record.serial_id, :issue_title => record.title, :project_id => record.project.id, :project_name => record.project.name}
        )
      end

      if record.user_id_was != record.user_id
        UserMailer.delay.issue_assign_notification(record, record.user) if record.user.notifier.issue_assign && record.user.notifier.can_notify
        ActivityFeed.create(
          :user => record.user,
          :kind => 'issue_assign_notification',
          :data => {:user_name => record.user.name, :issue_serial_id => record.serial_id, :project_id => record.project.id, :issue_title => record.title}
        )
      end

    when 'Comment'
      subscribes = record.commentable.subscribes
      subscribes.each do |subscribe|
        if record.user_id != subscribe.user_id
          if record.reply? subscribe
            UserMailer.delay.new_comment_reply_notification(record, subscribe.user) if record.can_notify_on_reply?(subscribe)
            ActivityFeed.create(
              :user => subscribe.user,
              :kind => 'new_comment_reply_notification',
              :data => {:user_name => subscribe.user.name, :comment_body => record.body, :issue_title => record.commentable.title, :issue_serial_id => record.commentable.serial_id, :project_id => record.commentable.project.id}
            )
          else
            UserMailer.delay.new_comment_notification(record, subscribe.user) if record.can_notify_on_new_comment?(subscribe)
            ActivityFeed.create(
              :user => subscribe.user,
              :kind => 'new_comment_notification',
              :data => {:user_name => subscribe.user.name, :comment_body => record.body, :issue_title => record.commentable.title, :issue_serial_id => record.commentable.serial_id, :project_id => record.commentable.project.id}
            )
          end
        end
      end
    when 'GitHook'
      change_type = record.change_type
      branch_name = record.refname.match(/\/([\w\d]+)$/)[1]
      #user_name = record.

      owner = record.owner
      project = Project.find_by_name(record.repo)

      last_commits = project.git_repository.repo.log(branch_name, nil).first(3).collect do |commit| #:author => 'author'
        [commit.sha, commit.message]
      end

      if change_type == 'delete'
        ActivityFeed.create(
          :user => owner,
          :kind => 'git_delete_branch_notification',
          :data => {:user_id => owner.id, :user_name => owner.uname,  :project_id => project.id, :project_name => project.name, :branch_name => branch_name, :change_type => change_type}
        )
      else
        ActivityFeed.create(
          :user => owner,#record.user,
          :kind => 'git_new_push_notification',
          :data => {:user_id => owner.id, :user_name => owner.uname, :project_id => project.id, :project_name => project.name, :last_commits => last_commits, :branch_name => branch_name, :change_type => change_type}
        )
      end
    end
  end

  def after_update(record)
    case record.class.to_s
    when 'Issue'
      if record.user_id_was != record.user_id
        UserMailer.delay.issue_assign_notification(record, record.user) if record.user.notifier.issue_assign && record.user.notifier.can_notify
        ActivityFeed.create(
          :user => record.user,
          :kind => 'issue_assign_notification',
          :data => {:user_name => record.user.name, :issue_serial_id => record.serial_id, :project_id => record.project.id, :issue_title => record.title}
        )
      end
    end
  end

  #def (partial_name, locals={})
  #  @@stub_controller ||= StubController.new
  #  @@stub_controller.partial_to_string('activity_feeds/partials/' + partial_name, locals)
  #end

end
