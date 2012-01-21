class Subscribe < ActiveRecord::Base
  belongs_to :subscribeable, :polymorphic => true
  belongs_to :user

  def self.new_comment_notification(comment)
    commentable_class = comment.commentable.class
    subscribes = comment.commentable.subscribes if commentable_class == Issue
    if commentable_class == Grit::Commit
      subscribes = comment.project.commit_comments_subscribes(true) # FIXME (true) for rspec
      committer = User.where(:email => comment.commentable.committer.email).first
      Subscribe.send_notification(comment, committer) if committer && committer.notifier.new_comment_commit_owner && subscribes.where(:user_id => committer).empty?
    end
    subscribes.each do |subscribe|
      user = subscribe.user
      next if comment.own_comment?(user) || !user.notifier.can_notify
      Subscribe.send_notification(comment, user) if commentable_class == Issue && user.notifier.new_comment_reply
      Subscribe.send_notification(comment, user) if commentable_class == Grit::Commit && Subscribe.send_notification_for_commit_comment?(subscribe.subscribeable, user, comment)
    end
  end

  def self.subscribe_user(project_id, user_id)
    list = Project.find(project_id).commit_comments_subscribes
    list.create(:user_id => user_id) unless list.exists?(:user_id => user_id)
  end

  def self.send_notification(comment, user)
    if Comment.where(:commentable_type => comment.commentable_type, :commentable_id => comment.commentable.id.to_s, :user_id => user.id).exists?
      UserMailer.delay.new_comment_reply_notification(comment, user)
    else
      UserMailer.delay.new_comment_notification(comment, user)
    end
  end

  def self.send_notification_for_commit_comment?(project, user, comment)
    is_owner = (project.owner_id == user.id)
    is_commentor = (project.commit_comments_subscribes.exists?(:user_id => user.id))
    (is_owner && user.notifier.new_comment_commit_repo_owner) or (is_commentor && user.notifier.new_comment_commit_commentor)
  end
end
