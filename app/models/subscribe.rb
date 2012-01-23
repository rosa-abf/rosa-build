class Subscribe < ActiveRecord::Base
  belongs_to :subscribeable, :polymorphic => true
  belongs_to :user
  belongs_to :project

  validates :status, :inclusion => {:in => 0..1}

  scope :subscribed, where(:status => 1)
  scope :unsubscribed, where(:status => 0)

  def self.new_comment_notification(comment)
    commentable_class = comment.commentable.class
    subscribes = comment.commentable.subscribes if commentable_class == Issue
    if commentable_class == Grit::Commit
      subscribes = Subscribe.where(:subscribeable_id => comment.commentable.id, :subscribeable_type => comment.commentable.class.name.to_s, :project_id => comment.project).subscribed(true) # FIXME (true) for rspec
    end
    subscribes.each do |subscribe|
      user = subscribe.user
      next if comment.own_comment?(user) || !user.notifier.can_notify
      UserMailer.delay.new_comment_notification(comment, user) if commentable_class == Issue && user.notifier.new_comment_reply
      UserMailer.delay.new_comment_notification(comment, user) if commentable_class == Grit::Commit
    end
  end

  def self.subscribe_user_to_commit(comment, user_id)
    subscribe = Subscribe.where(:subscribeable_id => comment.commentable.id, :subscribeable_type => comment.commentable.class.name, :project_id => comment.project).unsubscribed.first
    subscribe.update_attribute(:status, 1) if subscribe
    Subscribe.create(:subscribeable_id => comment.commentable.id, :subscribeable_type => comment.commentable.class.name.to_s, :user_id => user_id, :project_id => comment.project, :status => 1) unless subscribe
  end

  def self.subscribed_for_commit?(project, user, commentable)
    is_owner = (project.owner_id == user.id)
    is_commentor = (Comment.where(:commentable_type => commentable.class.name, :commentable_id => commentable.id).exists?(:user_id => user.id))
    is_committer = (user.email == commentable.committer.email)
    (is_owner && user.notifier.new_comment_commit_repo_owner) or (is_commentor && user.notifier.new_comment_commit_commentor) or (is_committer && committer.notifier.new_comment_commit_owner)
  end

  def self.set_subscribe(project, commit, user, status)
    # FIXME maybe?
    subscribe = Subscribe.where(:subscribeable_id => commit.id, :subscribeable_type => commit.class.name.to_s,
                    :user_id => user, :project_id => project).first
    if subscribe
      subscribe.update_attribute(:status, status)
    else
      Subscribe.create(:subscribeable_id => commit.id, :subscribeable_type => commit.class.name.to_s,
                       :user_id => user, :project_id => project, :status => status)
    end
  end
end
