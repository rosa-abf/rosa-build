class Subscribe < ActiveRecord::Base
  ON = 1
  OFF = 0
  belongs_to :subscribeable, :polymorphic => true
  belongs_to :user
  belongs_to :project

  validates :status, :inclusion => {:in => 0..1}

  scope :on, where(:status => ON)
  scope :off, where(:status => OFF)
  scope :finder_hack, order('') # FIXME .subscribes - error; .subscribes.finder_hack - success Oo

  def self.comment_subscribes(comment)
    Subscribe.where(:subscribeable_id => comment.commentable.id, :subscribeable_type => comment.commentable.class.name, :project_id => comment.project)
  end

  def self.new_comment_notification(comment)
    commentable_class = comment.commentable.class
    Subscribe.new_comment_issue_notification(comment) if commentable_class == Issue
    Subscribe.new_comment_commit_notification(comment) if commentable_class == Grit::Commit
  end

  def self.new_comment_issue_notification(comment)
    comment.commentable.subscribes.finder_hack.each do |subscribe|
      next if comment.own_comment?(subscribe.user) || !subscribe.user.notifier.can_notify
      UserMailer.delay.new_comment_notification(comment, subscribe.user) if subscribe.user.notifier.new_comment_reply
    end
  end

  def self.new_comment_commit_notification(comment)
    subscribes = Subscribe.comment_subscribes(comment).on#(true) # FIXME (true) for rspec
    subscribes.each do |subscribe|
      next if comment.own_comment?(subscribe.user) || !subscribe.user.notifier.can_notify
      UserMailer.delay.new_comment_notification(comment, subscribe.user)
    end
  end

  def self.subscribe_user_to_commit(comment, user)
    Subscribe.set_subscribe_to_commit(comment.project, comment.commentable, user, Subscribe::ON) if Subscribe.subscribed_to_commit?(comment.project, User.find(user), comment.commentable)
  end

  def self.subscribed_to_commit?(project, user, commentable)
    is_commentor = (Comment.where(:commentable_type => commentable.class.name, :commentable_id => commentable.id).exists?(:user_id => user.id))
    is_committer = (user.emails.exists? :email_lower => commentable.committer.email.downcase)
    return false if user.subscribes.where(:subscribeable_id => commentable.id, :subscribeable_type => commentable.class.name,
                     :project_id => project.id, :status => Subscribe::OFF).first.present?
    (project.owner?(user) && user.notifier.new_comment_commit_repo_owner) or
    (is_commentor && user.notifier.new_comment_commit_commentor) or
    (is_committer && user.notifier.new_comment_commit_owner)
  end

  def self.set_subscribe_to_commit(project, commit, user, status)
    options = {:subscribeable_id => commit.id, :subscribeable_type => commit.class.name, :user_id => user, :project_id => project.id}
    if subscribe = Subscribe.where(options).first # FIXME maybe?
      subscribe.update_attribute(:status, status)
    else
      Subscribe.create(options.merge(:status => status))
    end
  end
end
