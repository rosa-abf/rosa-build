# -*- encoding : utf-8 -*-
class Subscribe < ActiveRecord::Base
  belongs_to :subscribeable, :polymorphic => true
  belongs_to :user
  belongs_to :project

  scope :finder_hack, order('') # FIXME .subscribes - error; .subscribes.finder_hack - success Oo

  def subscribed?
    status
  end

  def self.comment_subscribes(comment)
    Subscribe.where(:subscribeable_id => comment.commentable.id, :subscribeable_type => comment.commentable.class.name, :project_id => comment.project)
  end

  def self.subscribed_to_commit?(project, user, commit)
    subscribe = user.subscribes.where(:subscribeable_id => commit.id, :subscribeable_type => commit.class.name, :project_id => project.id).first
    return subscribe.subscribed? if subscribe # return status if already subscribe present
    # return status by settings
    (project.owner?(user) && user.notifier.new_comment_commit_repo_owner) or
    (user.commentor?(commit) && user.notifier.new_comment_commit_commentor) or
    (user.committer?(commit) && user.notifier.new_comment_commit_owner)
  end

  def self.subscribe_to_commit(options)
    Subscribe.set_subscribe_to_commit(options, true)
  end

  def self.unsubscribe_from_commit(options)
    Subscribe.set_subscribe_to_commit(options, false)
  end

  private

  def self.set_subscribe_to_commit(options, status)
    if subscribe = Subscribe.where(options).first
      subscribe.update_attribute(:status, status)
    else
      Subscribe.create(options.merge(:status => status))
    end
  end

end
