class Comment < ActiveRecord::Base
  belongs_to :commentable, :polymorphic => true
  belongs_to :user

  validates :body, :user_id, :commentable_id, :commentable_type, :presence => true

  after_create :deliver_new_comment_notification

  protected

  def deliver_new_comment_notification
    recipients = self.commentable.project.relations.by_role('admin').where(:object_type => 'User').map { |rel| rel.read_attribute(:object_id) }
    recipients = recipients | [self.commentable.user_id]
    recipients = recipients | [self.commentable.project.owner_id] if self.commentable.project.owner_type == 'User'
    recipients.each do |recipient_id|
      recipient = User.find(recipient_id)
      UserMailer.delay.new_comment_notification(self, recipient)
    end
  end
end
