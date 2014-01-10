module Modules::Observers::ActivityFeed::Comment
  extend ActiveSupport::Concern

  included do
    after_commit :new_comment_notifications, :on => :create
    # dont remove outdated issues link
    after_update -> { Comment.create_link_on_issues_from_item(self) }
  end

  private

  def new_comment_notifications
    return if automatic?
    if issue_comment?
      commentable.subscribes.each do |subscribe|
        if user_id != subscribe.user_id
          UserMailer.new_comment_notification(self, subscribe.user).deliver if can_notify_on_new_comment?(subscribe)
          ActivityFeed.create(
            :user => subscribe.user,
            :kind => 'new_comment_notification',
            :data => {
              :user_name        => user.name,
              :user_email       => user.email,
              :user_id          => user_id,
              :comment_body     => body,
              :issue_title      => commentable.title,
              :issue_serial_id  => commentable.serial_id,
              :project_id       => commentable.project.id,
              :comment_id       => id,
              :project_name     => project.name,
              :project_owner    => project.owner.uname
            }
          )
        end
      end
    elsif commit_comment?
      Subscribe.comment_subscribes(self).where(:status => true).each do |subscribe|
        next if own_comment?(subscribe.user)
        if subscribe.user.notifier.can_notify and
            ( (subscribe.project.owner?(subscribe.user) && subscribe.user.notifier.new_comment_commit_repo_owner) or
              (subscribe.user.commentor?(self.commentable) && subscribe.user.notifier.new_comment_commit_commentor) or
              (subscribe.user.committer?(self.commentable) && subscribe.user.notifier.new_comment_commit_owner) )
          UserMailer.new_comment_notification(self, subscribe.user).deliver
        end
        ActivityFeed.create(
          :user => subscribe.user,
          :kind => 'new_comment_commit_notification',
          :data => {
            :user_name      => user.name,
            :user_email     => user.email,
            :user_id        => user_id,
            :comment_body   => body,
            :commit_message => commentable.message,
            :commit_id      => commentable.id,
            :project_id     => project.id,
            :comment_id     => id,
            :project_name   => project.name,
            :project_owner  => project.owner.uname}
        )
      end
    end
    Comment.create_link_on_issues_from_item(self)
  end

  def can_notify_on_new_comment?(subscribe)
    User.find(subscribe.user).notifier.new_comment && User.find(subscribe.user).notifier.can_notify
  end

end