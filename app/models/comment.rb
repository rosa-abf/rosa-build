# -*- encoding : utf-8 -*-
class Comment < ActiveRecord::Base
  belongs_to :commentable, :polymorphic => true
  belongs_to :user
  attr_accessor :project

  validates :body, :user_id, :commentable_id, :commentable_type, :presence => true

  # FIXME
  after_create :subscribe_on_reply, :unless => "commentable_type == 'Grit::Commit'"
  #after_create :deliver_new_comment_notification, :unless => "commentable_type == 'Grit::Commit'"
  after_create :invoke_helper, :if => "commentable_type == 'Grit::Commit'"
  after_create :subscribe_users
  after_create {|comment| Subscribe.new_comment_notification(comment)}

  def helper
    class_eval "def commentable; project.git_repository.commit('#{commentable_id}'); end" if commentable_type == 'Grit::Commit'
  end

  def own_comment?(user)
    user_id == user.id
  end

  def reply?(subscribe)
    self.commentable.comments.exists?(:user_id => subscribe.user.id)
  end

  def can_notify_on_reply?(subscribe)
    User.find(subscribe.user).notifier.new_comment_reply && User.find(subscribe.user).notifier.can_notify
  end

  def can_notify_on_new_comment?(subscribe)
    User.find(subscribe.user).notifier.new_comment && User.find(subscribe.user).notifier.can_notify
  end

  protected

  #def deliver_new_comment_notification
  #  subscribes = self.commentable.subscribes
  #  subscribes.each do |subscribe|
  #    # TODO: new_comment and new_comment_reply - you need to check each variant, not only new_comment_reply...
  #    if self.user_id != subscribe.user_id && User.find(subscribe.user).notifier.new_comment_reply && User.find(subscribe.user).notifier.can_notify
  #      if self.reply? subscribe
  #        UserMailer.delay.new_comment_reply_notification(self, subscribe.user)
  #      else
  #        UserMailer.delay.new_comment_notification(self, subscribe.user)
  #      end
  #    end
  #  end
  #end

  def subscribe_on_reply
    self.commentable.subscribes.create(:user_id => self.user_id) if !self.commentable.subscribes.exists?(:user_id => self.user_id)
  end

  def invoke_helper
    self.helper
  end

  def subscribe_users
    if self.commentable.class == Issue
      self.commentable.subscribes.create(:user => self.user) if !self.commentable.subscribes.exists?(:user_id => self.user.id)
    elsif self.commentable.class == Grit::Commit
      recipients = self.project.relations.by_role('admin').where(:object_type => 'User').map &:object # admins
      recipients << self.user << User.where(:email => self.commentable.committer.email).first # commentor and committer
      recipients << self.project.owner if self.project.owner_type == 'User' # project owner
      recipients.compact.uniq.each do |user|
        options = {:project_id => self.project.id, :subscribeable_id => self.commentable.id, :subscribeable_type => self.commentable.class.name, :user_id => user.id}
        Subscribe.subscribe_to_commit(options) if Subscribe.subscribed_to_commit?(self.project, user, self.commentable)
      end
    end
  end
end
