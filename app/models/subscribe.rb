class Subscribe < ActiveRecord::Base
  belongs_to :subscribeable, :polymorphic => true
  belongs_to :user

  def self.new_comment_notification(comment)
    commentable_class = comment.commentable.class
    subscribes = comment.commentable.subscribes if commentable_class == Issue
    if commentable_class == Grit::Commit
      Subscribe.subscribe_committer(comment)
      subscribes = comment.project.commit_comments_subscribes(true) # FIXME (true) for rspec
    end
    subscribes.each do |subscribe|
    user = subscribe.user
    next if comment.own_comment?(user) || !user.notifier.can_notify
    Subscribe.send_notification(comment, user) if commentable_class == Issue && user.notifier.new_comment_reply
    Subscribe.send_notification(comment, user) if commentable_class == Grit::Commit && user.notifier.new_comment_commit_repo_owner
    end
  end

  def self.subscribe_committer(comment)
    committer = User.where(:email => comment.commentable.committer.email).first
    if committer && !comment.project.commit_comments_subscribes.exists?(:user_id => committer.id) && committer.notifier.new_comment_commit_owner
      comment.project.commit_comments_subscribes.create(:user_id => committer.id)
    end
  end

  def self.send_notification(comment, user)
    if Comment.where(:commentable_type => comment.commentable_type, :commentable_id => comment.commentable.id.to_s, :user_id => user.id).exists?
      UserMailer.delay.new_comment_reply_notification(comment, user)
    else
      UserMailer.delay.new_comment_notification(comment, user)
    end
  end
end
