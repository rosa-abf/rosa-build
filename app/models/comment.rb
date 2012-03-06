# -*- encoding : utf-8 -*-
class Comment < ActiveRecord::Base
  belongs_to :commentable, :polymorphic => true
  belongs_to :user
  attr_accessor :project

  validates :body, :user_id, :commentable_id, :commentable_type, :presence => true

  default_scope order('created_at')

  after_create :subscribe_on_reply, :unless => lambda {|c| c.commit_comment?}
  after_create :helper, :if => lambda {|c| c.commit_comment?}
  after_create :subscribe_users

  attr_accessible :body, :commentable_id, :commentable_type

  def helper
    class_eval { def commentable; project.git_repository.commit(commentable_id.to_s(16)); end } if commit_comment?
  end

  def own_comment?(user)
    user_id == user.id
  end

  def commit_comment?
    commentable_type == 'Grit::Commit'
  end

  def can_notify_on_new_comment?(subscribe)
    User.find(subscribe.user).notifier.new_comment && User.find(subscribe.user).notifier.can_notify
  end

  protected

  def subscribe_on_reply
    self.commentable.subscribes.create(:user_id => self.user_id) if !self.commentable.subscribes.exists?(:user_id => self.user_id)
  end

  def subscribe_users
    if self.commentable.class == Issue
      self.commentable.subscribes.create(:user => self.user) if !self.commentable.subscribes.exists?(:user_id => self.user.id)
    elsif self.commit_comment?
      recipients = self.project.relations.by_role('admin').where(:object_type => 'User').map &:object # admins
      recipients << self.user << User.where(:email => self.commentable.committer.email).first # commentor and committer
      recipients << self.project.owner if self.project.owner_type == 'User' # project owner
      recipients.compact.uniq.each do |user|
        options = {:project_id => self.project.id, :subscribeable_id => self.commentable_id, :subscribeable_type => self.commentable.class.name, :user_id => user.id}
        Subscribe.subscribe_to_commit(options) if Subscribe.subscribed_to_commit?(self.project, user, self.commentable)
      end
    end
  end
end
