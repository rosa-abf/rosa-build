class Comment < ActiveRecord::Base
  belongs_to :commentable, :polymorphic => true
  belongs_to :user

  validates :body, :user_id, :commentable_id, :commentable_type, :presence => true

  after_create :subscribe_on_reply
  after_create :deliver_new_comment_notification

  protected

  def deliver_new_comment_notification
    subscribes = self.commentable.subscribes
    subscribes.each do |subscribe|
      recipient = subscribe.user
      if self.user_id != subscribe.user_id && User.find(recipient).notifier.new_comment_reply && User.find(recipient).notifier.can_notify
        if self.commentable.comments.exists?(:user_id => recipient.id)
          UserMailer.delay.new_comment_reply_notification(self, recipient)
        else
          UserMailer.delay.new_comment_notification(self, recipient)
        end
      end
    end
  end

  def subscribe_on_reply
    self.commentable.subscribes.create(:user_id => self.user_id) if !self.commentable.subscribes.exists?(:user_id => self.user_id)
  end
end
