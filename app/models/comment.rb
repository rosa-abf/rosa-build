class Comment < ActiveRecord::Base
  belongs_to :commentable, :polymorphic => true
  belongs_to :user
  attr_accessor :project

  validates :body, :user_id, :commentable_id, :commentable_type, :presence => true

  after_create :deliver_new_comment_notification

  protected

  def deliver_new_comment_notification
    return if self.commentable_type == 'Grit::Commit' # FIXME
    subscribes = self.commentable.subscribes
    subscribes.each do |subscribe|
      recipient = subscribe.user
      UserMailer.delay.new_comment_notification(self, recipient)
    end
  end
end
