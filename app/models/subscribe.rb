class Subscribe < ActiveRecord::Base
  belongs_to :subscribeable, polymorphic: true
  belongs_to :user
  belongs_to :project

  validates :user, presence: true

  def commit_subscribe?
    subscribeable_type == 'Grit::Commit'
  end

  def subscribed?
    status
  end

  def self.comment_subscribes(comment)
    Subscribe.where(subscribeable_id: comment.commentable_id, subscribeable_type: comment.commentable.class.name, project_id: comment.project)
  end

  def self.subscribed_to_commit?(project, user, commit)
    subscribe = user.subscribes.where(subscribeable_id: commit.id.hex, subscribeable_type: commit.class.name, project_id: project.id).first
    return subscribe.subscribed? if subscribe # return status if already subscribe present
    true
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
      subscribe.update_attributes(status: status)
    else
      Subscribe.create options.merge(status: status)
    end
  end

end
