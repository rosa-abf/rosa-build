module Feed::Comment
  extend ActiveSupport::Concern

  included do
    after_commit :new_comment_notifications, on: :create
    # dont remove outdated issues link
    after_update -> { Comment.create_link_on_issues_from_item(self) }
  end

  private

  def new_comment_notifications
    return if automatic?

    if issue_comment?
      commentable.subscribes.each do |subscribe|
        if can_notify_on_new_comment?(subscribe)
          UserMailer.new_comment_notification(self, subscribe.user_id).deliver unless own_comment?(subscribe.user)
          ActivityFeed.create(
            user_id:           subscribe.user_id,
            kind:              'new_comment_notification',
            project_owner:     project.owner_uname,
            project_name:      project.name,
            creator_id:        user_id,
            data: {
              creator_name:    user.name,
              creator_email:   user.email,
              comment_body:    body.truncate(100, omission: '…'),
              issue_title:     commentable.title,
              issue_serial_id: commentable.serial_id,
              project_id:      commentable.project.id,
              comment_id:      id
            }
          )
        end
      end
    elsif commit_comment?
      Subscribe.comment_subscribes(self).where(status: true).each do |subscribe|
        next if !subscribe.user_id
        if subscribe.user.notifier.can_notify && !own_comment?(subscribe.user)
            ( (subscribe.project.owner?(subscribe.user) && subscribe.user.notifier.new_comment_commit_repo_owner) ||
              (subscribe.user.commentor?(self.commentable) && subscribe.user.notifier.new_comment_commit_commentor) ||
              (subscribe.user.committer?(self.commentable) && subscribe.user.notifier.new_comment_commit_owner) )
          UserMailer.new_comment_notification(self, subscribe.user_id).deliver
        end
        ActivityFeed.create(
          user_id:          subscribe.user_id,
          kind:             'new_comment_commit_notification',
          project_owner:    project.owner_uname,
          project_name:     project.name,
          creator_id:       user_id,
          data:     {
            creator_name:   user.name,
            creator_email:  user.email,

            comment_body:   body.truncate(100, omission: '…'),
            commit_message: commentable.message.truncate(70, omission: '…'),
            commit_id:      commentable.id,
            project_id:     project.id,
            comment_id:     id
          }
        )
      end
    end
    Comment.create_link_on_issues_from_item(self)
  end

  def can_notify_on_new_comment?(subscribe)
    notifier = SettingsNotifier.find_by user_id: subscribe.user_id
    notifier && notifier.new_comment && notifier.can_notify
  end
end
