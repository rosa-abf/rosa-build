# -*- encoding : utf-8 -*-
class Comment < ActiveRecord::Base
  belongs_to :commentable, :polymorphic => true
  belongs_to :user
  belongs_to :project

  validates :body, :user_id, :commentable_id, :commentable_type, :project_id, :presence => true

  scope :for_commit, lambda {|c| where(:commentable_id => c.id.hex, :commentable_type => c.class)}
  default_scope order('created_at')

  after_create :subscribe_on_reply, :unless => lambda {|c| c.commit_comment?}
  after_create :subscribe_users

  attr_accessible :body

  def commentable
    # raise commentable_id.inspect
    # raise commentable_id.to_s(16).inspect
    commit_comment? ? project.repo.commit(commentable_id.to_s(16)) : super # TODO leading zero problem
  end

  def commentable=(c)
    if self.class.commit_comment?(c.class)
      self.commentable_id = c.id.hex
      self.commentable_type = c.class.name
    else
      super
    end
  end

  def self.commit_comment?(class_name)
    class_name.to_s == 'Grit::Commit'
  end

  def commit_comment?
    self.class.commit_comment?(commentable_type)
  end

  def self.issue_comment?(class_name)
    class_name.to_s == 'Issue'
  end

  def issue_comment?
    self.class.issue_comment?(commentable_type)
  end

  def own_comment?(user)
    user_id == user.id
  end

  def can_notify_on_new_comment?(subscribe)
    User.find(subscribe.user).notifier.new_comment && User.find(subscribe.user).notifier.can_notify
  end

  protected

  def subscribe_on_reply
    commentable.subscribes.create(:user_id => user_id) if !commentable.subscribes.exists?(:user_id => user_id)
  end

  def subscribe_users
    if issue_comment?
      commentable.subscribes.create(:user => user) if !commentable.subscribes.exists?(:user_id => user.id)
    elsif commit_comment?
      recipients = project.relations.by_role('admin').where(:actor_type => 'User').map &:actor # admins
      recipients << user << User.where(:email => commentable.committer.email).first # commentor and committer
      recipients << project.owner if project.owner_type == 'User' # project owner
      recipients.compact.uniq.each do |user|
        options = {:project_id => project.id, :subscribeable_id => commentable_id, :subscribeable_type => commentable.class.name, :user_id => user.id}
        Subscribe.subscribe_to_commit(options) if Subscribe.subscribed_to_commit?(project, user, commentable)
      end
    end
  end
end
