class Comment < ActiveRecord::Base
  belongs_to :commentable, :polymorphic => true
  belongs_to :user
  attr_accessor :project

  validates :body, :user_id, :commentable_id, :commentable_type, :presence => true

  after_create :invoke_helper, :if => "commentable_type == 'Grit::Commit'"
  after_create :subscribe_on_reply
  after_create :subscribe_users, :if => "commentable_type == 'Grit::Commit'"
  after_create {|comment| Subscribe.new_comment_notification(comment)}

  def helper
    class_eval "def commentable; project.git_repository.commit('#{commentable_id}'); end" if commentable_type == 'Grit::Commit'
  end

  def own_comment?(user)
    user_id == user.id
  end

  protected

  def subscribe_on_reply
    self.commentable.subscribes.create(:user_id => self.user_id) if self.commentable_type == 'Issue' && !self.commentable.subscribes.exists?(:user_id => self.user_id)
    Subscribe.subscribe_user_to_commit(self, self.user.id) if self.commentable_type == 'Grit::Commit'
  end

  def invoke_helper
    self.helper
  end

  def subscribe_users
    recipients = self.project.relations.by_role('admin').where(:object_type => 'User').map { |rel| rel.read_attribute(:object_id) }
    committer = User.where(:email => self.commentable.committer.email).first
    recipients = recipients | [committer.id] if committer
    recipients = recipients | [self.project.owner_id] if self.project.owner_type == 'User'
    recipients.each {|user| Subscribe.subscribe_user_to_commit(self, user)}
  end
end
