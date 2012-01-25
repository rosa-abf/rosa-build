class ActivityFeedObserver < ActiveRecord::Observer
  observe :issue, :comment

  def after_create(record)
    case record.class.to_s
    when 'User'
      ActivityFeed.create(:user => record, :body => render_body('new_user_notification'))
    when 'Issue'
      recipients = record.collect_recipient_ids
      recipients.each do |recipient_id|
        recipient = User.find(recipient_id)
        UserMailer.delay.new_issue_notification(record, recipient) if User.find(recipient).notifier.can_notify && User.find(recipient).notifier.new_issue
        ActivityFeed.create(:user => record, :body => render_body('new_issue_notification', {:user => recipient, :issue => record}))
      end

      UserMailer.delay.issue_assign_notification(record, record.user) if record.user_id_was != record.user_id && record.user.notifier.issue_assign && record.user.notifier.can_notify
      ActivityFeed.create(:user => record.user, :body => render_body('issue_assign_notification', {:user => record.user, :issue => record}))
    when 'Comment'
      subscribes = record.commentable.subscribes
      subscribes.each do |subscribe|
        if record.user_id != subscribe.user_id
          if record.reply? subscribe
            UserMailer.delay.new_comment_reply_notification(record, subscribe.user) if record.can_notify_on_reply?(subscribe)
            ActivityFeed.create(:user => record.user, :body => render_body('new_comment_reply_notification', {:user => subscribe.user, :comment => record}))
          else
            UserMailer.delay.new_comment_notification(record, subscribe.user) if record.can_notify_on_new_comment?(subscribe)
            ActivityFeed.create(:user => record.user, :body => render_body('new_comment_notification', {:user => subscribe.user, :comment => record}))
          end
        end
      end
    end
  end

  def after_update(record)
    case record.class.to_s
    when 'Issue'
      UserMailer.delay.issue_assign_notification(record, record.user) if record.user_id_was != record.user_id && record.user.notifier.issue_assign && record.user.notifier.can_notify
      ActivityFeed.create(:user => record.user, :body => render_body('issue_assign_notification', {:user => record.user, :issue => record}))
    end
  end

  def render_body(partial_name, locals={})
    #ac = ActionController::Base.new
    #ac.render_to_string(
    #  'app/views/activity_feeds/partials/' + partial_name + '.haml',
    #  :locals => locals
    #)

    #ac = ActionView::Base.new([], locals)
    #ac.render(:inline => 'app/views/activity_feeds/partials/' + partial_name + '.haml')
    
    StubController.new.partial_to_string('activity_feeds/partials/' + partial_name, locals)
  end

end
