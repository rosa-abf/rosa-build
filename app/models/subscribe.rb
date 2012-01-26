class Subscribe < ActiveRecord::Base
  belongs_to :subscribeable, :polymorphic => true
  belongs_to :user

  def self.new_comment_notification(comment)
    commentable_class = comment.commentable.class
    subscribes = comment.commentable.subscribes if commentable_class == Issue
    if commentable_class == Grit::Commit
      subscribes = comment.project.commit_comments_subscribes(true) # FIXME (true) for rspec
      committer = User.includes(:user_emails).where("user_emails.email = ?", comment.commentable.committer.email).first
      UserMailer.delay.new_comment_notification(comment, committer) if committer && !comment.own_comment?(committer) && committer.notifier.new_comment_commit_owner && !committer.notifier.can_notify && subscribes.where(:user_id => committer).empty?
    end
    subscribes.each do |subscribe|
      user = subscribe.user
      next if comment.own_comment?(user) || !user.notifier.can_notify
      UserMailer.delay.new_comment_notification(comment, user) if commentable_class == Issue && user.notifier.new_comment_reply
      UserMailer.delay.new_comment_notification(comment, user) if commentable_class == Grit::Commit && Subscribe.send_notification_for_commit_comment?(subscribe.subscribeable, user, comment)
    end
  end

  def self.subscribe_user(project_id, user_id)
    list = Project.find(project_id).commit_comments_subscribes
    list.create(:user_id => user_id) unless list.exists?(:user_id => user_id)
  end

  def self.send_notification_for_commit_comment?(project, user, comment)
    is_owner = (project.owner_id == user.id)
    is_commentor = (project.commit_comments_subscribes.exists?(:user_id => user.id))
    (is_owner && user.notifier.new_comment_commit_repo_owner) or (is_commentor && user.notifier.new_comment_commit_commentor)
  end
end
